const { run } = require("hardhat")

const verify = async (contracAdress, args) => {
  console.log("Verifying contract .....")

  try {
    await run("verify:verify", {
      address: contracAdress,
      constructorArguments: args,
    })
  } catch (error) {
    error.message.toLowerCase().includes("already verified")
      ? console.log("Already verified")
      : console.log(error)
  }
}

module.exports = { verify }