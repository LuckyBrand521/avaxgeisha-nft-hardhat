import {ethers} from 'hardhat'

async function main() {
    const [deployer] = await ethers.getSigners()
    if (deployer === undefined) throw new Error('Deployer is undefined.')
    console.log('Deploying contracts with the account:', deployer.address)

    console.log('Account balance:', (await deployer.getBalance()).toString())

    const AvaxGeisha = await ethers.getContractFactory('AvaxGeisha')

    const avaxGeishaDeployed = await AvaxGeisha.deploy([])

    console.log('AvaxGeisha:', avaxGeishaDeployed.address)

    const Marketplace = await ethers.getContractFactory('Marketplace')

    const marketPlaceDeployed = await Marketplace.deploy([])

    console.log('MarketPlace:', marketPlaceDeployed.address)
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error)
        process.exit(1)
    })

// 0x2D99ABD9008Dc933ff5c0CD271B88309593aB921


/*
Address:      0xcF2370872F7628b3e41c3A6e30b5BA9cfE95CdF9
Private Key:  e2a51d2a8323e806b7c334665b60ec6a3633f628856fc88438f44dde5b1092ae


Address:      0x7A260df520bEFe9217EB546a3232f4Df11138423
Private Key:  2c6f097a8cd842c2ee7811d5ae5180142aa30525ea3db3362032bbea47acf121

*/