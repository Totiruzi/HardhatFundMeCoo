const { deployments, ethers, getNamedAccounts } = require('hardhat')
const { assert, expect } = require('chai')

describe('FundMe', async function() {
  let fundMe
  let deployer
  let mockV3Aggregator
  const sendValue = ethers.utils.parseEther('1') // 1ETH
  beforeEach(async function() {
    // deploy our FundMe contract
    // using hardhat deploy
    // const accounts = ethers.getNamedSigner() //The same way to get different acounts
    // const accountZero = accounts[0]
    deployer  = (await getNamedAccounts()).deployer
    await deployments.fixture(['all'])
    fundMe = await ethers.getContract('FundMe', deployer)
    mockV3Aggregator = await ethers.getContract('MockV3Aggregator', deployer)
  })
  describe('Constructor', async function() {
    it('sets the aggregator addresses corectly', async function() {
      const response = await fundMe.priceFeed()
      assert.equal(response, mockV3Aggregator.address)
    })
  })

  describe('fund', async function() {
    it(`Fails if you don't send enough ETH`, async function() {
      await expect(fundMe.fund()).to.be.revertedWith('You need to spend more ETH!')
    })

    it('update the amount funded data structure', async function() {
      await fundMe.fund({value: sendValue})
      const response = await fundMe.addressToAmountFunded(deployer)
      assert.equal(response.toString(), sendValue.toString())
    })

    it('Add funder to array of funders', async function() {
      await fundMe.fund({value: sendValue})
      const funder = await fundMe.funders(0)
      assert.equal(funder, deployer)
    })
  })

  describe("Withdrawer", async function() {
    beforeEach(async function() {
      await fundMe.fund({value: sendValue})
    })

    it('withdraw Eth from a single founder', async function() {
      // Arrange
      const startingFundMeBalance = await fundMe.provider.getBalance(fundMe.address)
      const startingDeployerBalance = await fundMe.provider.getBalance(deployer)

      // Act
      const transactionResponse = await fundMe.withdraw()
      const transactionReceipt = await transactionResponse.wait(1)
      const { gasUsed, effectiveGasPrice } = transactionReceipt
      const gasCost = gasUsed.mul(effectiveGasPrice)

      const endingFundMeBalance = await fundMe.provider.getBalance(fundMe.address)
      const endingDeployBalance = await fundMe.provider.getBalance(deployer)

      // Assert
      assert.equal(endingFundMeBalance, 0)
      assert.equal(startingFundMeBalance.add(startingDeployerBalance).toString(), endingDeployBalance.add(gasCost).toString())
    })

    it('allows us to withdraw with multiple funders', async function() {
      // Arrange
      const accounts = await ethers.getSigners()
      for (let i = 1; i < 6; i++) {
        const fundMeConnectedContract = await fundMe.connect(accounts[i])
        await fundMeConnectedContract.fund({value: sendValue})
      }
      const startingFundMeBalance = await fundMe.provider.getBalance(fundMe.address)
      const startingDeployerBalance = await fundMe.provider.getBalance(deployer)


      // Act
      const transactionResponse = await fundMe.withdraw()
      const transactionReceipt = await transactionResponse.wait(1)
      const { gasUsed, effectiveGasPrice } = transactionReceipt
      const gasCost = gasUsed.mul(effectiveGasPrice)

      // Asert
      const endingFundMeBalance = await fundMe.provider.getBalance(fundMe.address)
      const endingDeployBalance = await fundMe.provider.getBalance(deployer)
      assert.equal(endingFundMeBalance, 0)
      assert.equal(
        startingFundMeBalance.add(startingDeployerBalance).toString(), 
        endingDeployBalance.add(gasCost).toString())

      // Make sure that the funders are reset properly
      await expect(fundMe.funders(0)).to.be.reverted

      for(i = 1; i < 6; i++) {
        assert.equal(await fundMe.addressToAmountFunded(accounts[i].address), 0)
      }
    })

    it('only allows the owner to withdraw', async function() {
      const accounts = await ethers.getSigners()
      const attacker = accounts[1]
      const attackerConnectedContract = await fundMe.connect(attacker)
      await expect(attackerConnectedContract.withdraw()).to.be.revertedWith('Sender not owner')
      // const fundMeConnectedContract = await fundMe.connect(accounts[1])
      // await expect(fundMeConnectedContract.withdraw()).to.be.revertedWith('FundMe__NotOwner')
    })
    
  })
})