import { ethers } from "hardhat";

function toBytes32(number) {
    return ethers.utils.hexZeroPad(ethers.utils.hexValue(ethers.BigNumber.from(number)), 32);
}

function toBytes20(number) {
    return ethers.utils.hexZeroPad(ethers.utils.hexValue(ethers.BigNumber.from(number)), 20);
}

function toByte1(number) {
    return ethers.utils.hexZeroPad(ethers.utils.hexValue(ethers.BigNumber.from(number)), 1);
}
  
function mintParamToBytes(typeId, restriction = false) {
    const typeIdHex = toBytes32(typeId);
    const restrictionHex = toByte1(restriction ? 1 : 0);
    return ethers.utils.hexConcat([typeIdHex, restrictionHex]);
}

function mintByTypeParamToBytes(restriction = false) {
    return toByte1(restriction ? 1 : 0);
}

function addTypeParamToBytes(addressErc20ToLock = "0", amountToLock = "0", durationLockDestroy = "0", mintingDurationLock = "0", numberReserved = "0") {
    const amountToLockHex = toBytes32(amountToLock);
    const durationLockDestroyHex = toBytes32(durationLockDestroy);
    const mintingDurationLockHex = toBytes32(mintingDurationLock);
    const numberReservedHex = toBytes32(numberReserved);

    return ethers.utils.hexConcat([addressErc20ToLock !== "0" ? addressErc20ToLock : ethers.constants.AddressZero, amountToLockHex, durationLockDestroyHex, mintingDurationLockHex, numberReservedHex]);
}

function parseDataTypes(data) {
    const tokenToLock = `0x${data.slice(2, 42)}`;
    const amountToLock = ethers.BigNumber.from(`0x${data.slice(43, 43+64)}`).toString();
    const durationLockDestroy = ethers.BigNumber.from(`0x${data.slice(106, 106+64)}`).toString();
    const mintingStartingTime = ethers.BigNumber.from(`0x${data.slice(170, 170+64)}`).toString();
    const numberReserved = ethers.BigNumber.from(`0x${data.slice(234, 234+64)}`).toString();
    return {
        tokenToLock,
        amountToLock,
        durationLockDestroy,
        mintingStartingTime,
        numberReserved,
    }
}

export { toBytes32, toByte1, mintParamToBytes, mintByTypeParamToBytes, addTypeParamToBytes, parseDataTypes};