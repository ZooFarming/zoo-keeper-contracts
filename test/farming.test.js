const { expectRevert, time } = require('@openzeppelin/test-helpers');
const ZooToken = artifacts.require('ZooToken');
const ZooKeeperFarming = artifacts.require('ZooKeeperFarming');
const MockERC20 = artifacts.require('MockERC20');

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'


contract('ZooKeeperFarming', ([alice, bob, carol, dev, minter]) => {
    beforeEach(async () => {
        this.zoo = await ZooToken.new({ from: alice });
    });

    it('should set correct state variables', async () => {
        this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
            ZERO_ADDRESS,
            '10000000000000000000',
            0,
            99999999,
            ZERO_ADDRESS,
            ZERO_ADDRESS, { from: alice });
        await this.zoo.transferOwnership(this.farm.address, { from: alice });
        const zoo = await this.farm.zoo();
        const devaddr = await this.farm.devaddr();
        const owner = await this.zoo.owner();
        assert.equal(zoo.valueOf(), this.zoo.address);
        assert.equal(devaddr.valueOf(), dev);
        assert.equal(owner.valueOf(), this.farm.address);
    });

    it('should allow dev and only dev to update dev', async () => {
        this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
            ZERO_ADDRESS,
            '10000000000000000000',
            0,
            99999999,
            ZERO_ADDRESS,
            ZERO_ADDRESS, { from: alice });
        assert.equal((await this.farm.devaddr()).valueOf(), dev);
        await expectRevert(this.farm.dev(bob, { from: bob }), 'Should be dev address');
        await this.farm.dev(bob, { from: dev });
        assert.equal((await this.farm.devaddr()).valueOf(), bob);
        await this.farm.dev(alice, { from: bob });
        assert.equal((await this.farm.devaddr()).valueOf(), alice);
    })

    context('With ERC/LP token added to the field', () => {
        beforeEach(async () => {
            this.lp = await MockERC20.new('LPToken', 'LP', 18, '10000000000', { from: minter });
            await this.lp.transfer(alice, '1000', { from: minter });
            await this.lp.transfer(bob, '1000', { from: minter });
            await this.lp.transfer(carol, '1000', { from: minter });
            this.lp2 = await MockERC20.new('LPToken2', 'LP2', 18, '10000000000', { from: minter });
            await this.lp2.transfer(alice, '1000', { from: minter });
            await this.lp2.transfer(bob, '1000', { from: minter });
            await this.lp2.transfer(carol, '1000', { from: minter });

            this.lp3 = await MockERC20.new('LPToken3', 'LP3', 4, '10000000000', { from: minter });
            await this.lp3.transfer(alice, '1000', { from: minter });
            await this.lp3.transfer(bob, '1000', { from: minter });
            await this.lp3.transfer(carol, '1000', { from: minter });

            this.lp4 = await MockERC20.new('LPToken4', 'LP4', 8, '10000000000', { from: minter });
            await this.lp4.transfer(alice, '1000', { from: minter });
            await this.lp4.transfer(bob, '1000', { from: minter });
            await this.lp4.transfer(carol, '1000', { from: minter });
        });

        it('should give out ZOOs only after farming time', async () => {
            // 100 per block farming rate starting at block 100 with bonus until block 1000
            this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
                ZERO_ADDRESS,
                '100',
                100,
                99999999,
                ZERO_ADDRESS,
                ZERO_ADDRESS, { from: alice });
            await this.zoo.transferOwnership(this.farm.address, { from: alice });
            await this.farm.add('100', this.lp.address, true, 0, false);
            await this.farm.set(0, '50', true);
            await this.farm.set(0, '100', false);
            await this.lp.approve(this.farm.address, '1000', { from: bob });
            await this.farm.deposit(0, '100', 0, 0, { from: bob });
            await time.advanceBlockTo('89');
            await this.farm.withdraw(0, '0', { from: bob }); // block 90
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('94');
            await this.farm.withdraw(0, '0', { from: bob }); // block 95
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('99');
            await this.farm.withdraw(0, '0', { from: bob }); // block 100
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '0');
            await time.advanceBlockTo('100');
            await this.farm.withdraw(0, '0', { from: bob }); // block 101
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '100');
            await time.advanceBlockTo('104');
            await this.farm.withdraw(0, '0', { from: bob }); // block 105
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '500');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '140');
            assert.equal((await this.zoo.totalSupply()).valueOf(), '640');
        });

        it('should not distribute ZOOs if no one deposit', async () => {
            // 100 per block farming rate starting at block 200 with bonus until block 1000
            this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
                ZERO_ADDRESS,
                '100',
                200,
                99999999,
                ZERO_ADDRESS,
                ZERO_ADDRESS, { from: alice });
            await this.zoo.transferOwnership(this.farm.address, { from: alice });
            await this.farm.add('100', this.lp.address, true, 0, false);
            await this.lp.approve(this.farm.address, '1000', { from: bob });
            await time.advanceBlockTo('199');
            assert.equal((await this.zoo.totalSupply()).valueOf(), '0');
            await time.advanceBlockTo('204');
            assert.equal((await this.zoo.totalSupply()).valueOf(), '0');
            await time.advanceBlockTo('209');
            await this.farm.deposit(0, '10', 0, 0, { from: bob }); // block 210
            assert.equal((await this.zoo.totalSupply()).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '0');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '990');
            await time.advanceBlockTo('219');
            await this.farm.withdraw(0, '10', { from: bob }); // block 220
            assert.equal((await this.zoo.totalSupply()).valueOf(), '1280');
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '1000');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '280');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '1000');
        });

        it('should distribute ZOOs properly for each staker', async () => {
            // 100 per block farming rate starting at block 300 with bonus until block 1000
            this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
                ZERO_ADDRESS,
                '100',
                300,
                99999999,
                ZERO_ADDRESS,
                ZERO_ADDRESS, { from: alice });
            await this.zoo.transferOwnership(this.farm.address, { from: alice });
            await this.farm.add('100', this.lp.address, true, 0, false);
            await this.lp.approve(this.farm.address, '1000', { from: alice });
            await this.lp.approve(this.farm.address, '1000', { from: bob });
            await this.lp.approve(this.farm.address, '1000', { from: carol });
            // Alice deposits 10 LPs at block 310
            await time.advanceBlockTo('309');
            await this.farm.deposit(0, '10', 0, 0, { from: alice });
            console.log('t 310', (await this.zoo.totalSupply()).toString());
            await time.advanceBlockTo('311');
            console.log('t 311', (await this.zoo.totalSupply()).toString());
            await time.advanceBlockTo('312');
            console.log('t 312', (await this.zoo.totalSupply()).toString());
            // Bob deposits 20 LPs at block 314
            await time.advanceBlockTo('313');
            console.log('t 313', (await this.zoo.totalSupply()).toString());
            await this.farm.deposit(0, '20', 0, 0, { from: bob });
            console.log('t 314', (await this.zoo.totalSupply()).toString());

            // Carol deposits 30 LPs at block 318
            await time.advanceBlockTo('317');
            await this.farm.deposit(0, '30', 0, 0, { from: carol });
            console.log('t 317', (await this.zoo.totalSupply()).toString());

            // Alice deposits 10 more LPs at block 320. At this point:
            //   Alice should have: 4*100 + 4*1/3*100 + 2*1/6*100 = 566
            await time.advanceBlockTo('319')
            await this.farm.deposit(0, '10', 0, 0, { from: alice });
            console.log('t320', (await this.zoo.totalSupply()).toString());
            console.log('a320', (await this.zoo.balanceOf(this.farm.address)).toString());

            assert.equal((await this.zoo.totalSupply()).valueOf(), '724');
            assert.equal((await this.zoo.balanceOf(alice)).valueOf(), '566');
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(carol)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(this.farm.address)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '158');
            // Bob withdraws 5 LPs at block 330. At this point:
            //   Bob should have: 4*2/3*100 + 2*2/6*100 + 10*2/7*100 = 619
            await time.advanceBlockTo('329')
            await this.farm.withdraw(0, '5', { from: bob });
            assert.equal((await this.zoo.totalSupply()).valueOf(), '1516');
            assert.equal((await this.zoo.balanceOf(alice)).valueOf(), '566');
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '619');
            assert.equal((await this.zoo.balanceOf(carol)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(this.farm.address)).valueOf(), '0');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '331');
            // Alice withdraws 20 LPs at block 340.
            // Bob withdraws 15 LPs at block 350.
            // Carol withdraws 30 LPs at block 360.
            await time.advanceBlockTo('339')
            await this.farm.withdraw(0, '20', { from: alice });
            await time.advanceBlockTo('349')
            await this.farm.withdraw(0, '15', { from: bob });
            await time.advanceBlockTo('359')
            await this.farm.withdraw(0, '30', { from: carol });
            assert.equal((await this.zoo.totalSupply()).valueOf(), '6396');
            assert.equal((await this.zoo.balanceOf(dev)).valueOf(), '1397');
            // Alice should have: 566 + 10*2/7*100 + 10*2/6.5*100 = 1160
            assert.equal((await this.zoo.balanceOf(alice)).valueOf(), '1159');
            // Bob should have: 619 + 10*1.5/6.5*100 + 10*1.5/4.5*100 = 1183
            assert.equal((await this.zoo.balanceOf(bob)).valueOf(), '1183');
            // Carol should have: 2*3/6*100 + 10*3/7*100 + 10*3/6.5*100 + 10*3/4.5*100 + 10*100 = 2657
            assert.equal((await this.zoo.balanceOf(carol)).valueOf(), '2657');
            // All of them should have 1000 LPs back.
            assert.equal((await this.lp.balanceOf(alice)).valueOf(), '1000');
            assert.equal((await this.lp.balanceOf(bob)).valueOf(), '1000');
            assert.equal((await this.lp.balanceOf(carol)).valueOf(), '1000');

            let poolLength = await this.farm.poolLength();
            console.log('poolLength', poolLength);

        });

        it('should give proper ZOO allocation to each pool', async () => {
            // 100 per block farming rate starting at block 400 with bonus until block 1000
            this.farm = await ZooKeeperFarming.new(this.zoo.address, dev,
                ZERO_ADDRESS,
                '100',
                400,
                1000,
                ZERO_ADDRESS,
                ZERO_ADDRESS, { from: alice });
            await this.zoo.transferOwnership(this.farm.address, { from: alice });
            await this.lp.approve(this.farm.address, '1000', { from: alice });
            await this.lp2.approve(this.farm.address, '1000', { from: bob });
            // Add first LP to the pool with allocation 1
            await this.farm.add('10', this.lp.address, true, 0, false);
            // Alice deposits 10 LPs at block 410
            await time.advanceBlockTo('409');
            await this.farm.deposit(0, '10', 0, 0, { from: alice });
            // Add LP2 to the pool with allocation 2 at block 420
            await time.advanceBlockTo('419');
            await this.farm.add('20', this.lp2.address, true, 0, false);
            // Alice should have 10*100 pending reward
            assert.equal((await this.farm.pendingZoo(0, alice)).valueOf(), '1000');
            // Bob deposits 10 LP2s at block 425
            await time.advanceBlockTo('424');
            await this.farm.deposit(1, '5', 0, 0, { from: bob });
            // Alice should have 1000 + 5*1/3*100 = 1167 pending reward
            assert.equal((await this.farm.pendingZoo(0, alice)).valueOf(), '1166');
            await time.advanceBlockTo('430');
            // At block 430. Bob should get 5*2/3*100 = 333.
            // At block 430. Alice should get 1166 + 5*1/3*100 = 1333.
            assert.equal((await this.farm.pendingZoo(0, alice)).valueOf(), '1333');
            assert.equal((await this.farm.pendingZoo(1, bob)).valueOf(), '333');
        });
    });
});
