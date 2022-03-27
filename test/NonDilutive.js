const { assert } = require('chai')
const { ethers } = require("hardhat");

const chai = require('chai')
    .use(require('chai-as-promised'))
    .should()

describe("Non-Dilutive Token", () => {
    before(async () => {
        [
            owner,
            address1,
            address2
        ] = await ethers.getSigners();

        priceInWei = "20000000000000000"

        MigratedContract = await ethers.getContractFactory("MockToken");
        migratedContract = await MigratedContract.deploy(
            "migrate",
            "mgrt"
        )

        Contract = await ethers.getContractFactory("NonDilutive");
        contract = await Contract.deploy(
            "Non-Dilutive",
            "No-D",
            "ipfs://unrevealed/",
            "ipfs://generation-zero/",
            900
        );

        contract = await contract.deployed();
    })

    it('Contract deploys successfully.', async() => {
        address = contract.address
        assert.notEqual(address, '')
        assert.notEqual(address, 0x0)
        assert.notEqual(address, null)
        assert.notEqual(address, undefined)
    });

    it('Contract has a name.', async() => {
        let name = await contract.name()
        assert.equal(name, 'Non-Dilutive')
    });

    it('Contract has the right price.', async() => {
        price = await contract.COST();
        assert.equal(price.toString(), priceInWei)
    });

    it('Toggle mint.', async() => {
        tx = await contract.toggleMint()
        tx.wait()
        assert.equal((await contract.mintOpen()).toString(), "true")        
    });

    it('Minting 1 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(1, { value: ethers.utils.parseEther("0.02") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "2")
    });

    it('Minting 2 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(2, { value: ethers.utils.parseEther("0.04") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "4")
    });

    it('Minting 10 in public sale.', async() => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        await hre.network.provider.send("hardhat_setBalance", [mintingAddress, "0x999999999999999999999",]);
        
        totalSupply = await contract.totalSupply()

        var mintSigner = await ethers.getSigner(mintingAddress)
        await contract.connect(mintSigner).mint(10, { value: ethers.utils.parseEther("0.2") })

        totalSupply = await contract.totalSupply()
        assert.equal(totalSupply.toString(), "14")
    });

    it('Validate token uri', async () => { 
        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes("ipfs://unrevealed/"), true);
    });

    it('Reveal generation zero', async () => { 
        await contract.setRevealed(0, 500);
        await contract.setRevealed(0, 200).should.be.revertedWith('TokenRevealed');
    });

    it('Validate token uri after having revealed', async () => { 
        // get the base token id of this genreation
        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`ipfs://generation-zero/`), true);
    });

    it('Get token generation', async () => {
        generation = await contract.getTokenGeneration(1);
        assert.equal(generation.toString(), "0");
    });

    it('Getting token generation fails for tokens not minted', async () => { 
        generation = await contract.getTokenGeneration(100).should.be.rejectedWith('TokenNonExistent')
    });

    it('Reconnecting layer zero fails', async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(0, 1).should.be.revertedWith("GenerationNotDifferent")
    });

    it("Connect generation 1", async () => { 
        await contract.loadGeneration(
            1,
            false,
            true,
            false,
            0,
            0,
            'ipfs://generation-one/'
        )
    });

    it("Connect reconnect generation 1", async () => { 
        await contract.loadGeneration(
            1,
            true,
            true,
            false,
            0,
            0,
            'ipfs://generation-one/'
        ).should.be.revertedWith('GenerationAlreadyLoaded')
    });

    it("Cannot focus generation 1 while disabled", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1).should.be.revertedWith("GenerationNotEnabled")
    });

    it("Enable generation 1", async () => { 
       await contract.toggleGeneration(1);
    });

    it("Disable generation 1 should fail", async () => { 
        await contract.toggleGeneration(1).should.be.revertedWith('GenerationNotToggleable');
    });

    it("Can now focus generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1)
    });

    it('Validate token uri is unrevealed after generation 1 upgrade', async () => { 
        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes("ipfs://unrevealed/"), true);
    });

    it("Can focus generation 0 after upgrading to generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(0, 1)

        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`ipfs://generation-zero/`), true);
    });

    it('Reveal generation 1 assets', async () => { 
        await contract.setRevealed(1, 500);
    });

    it("Can reenable generation 1", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1)

        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`ipfs://generation-one/`), true);
    })

    it("Load generation 2", async () => { 
        await contract.loadGeneration(
            2,
            true,
            true,
            true,
            '20000000000000000',
            0,
            'ipfs://generation-two/'
        )

        await contract.setRevealed(2, 500);
    });

    it("Focus generation 2 while paying", async () => { 
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(2, 1, { value: ethers.utils.parseEther("0.02")});

        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`ipfs://generation-two/`), true);
    });

    it("Cannot downgrade from generation 2", async () => {
        var mintingAddress = "0x62180042606624f02D8A130dA8A3171e9b33894d"
        await hre.network.provider.request({method: "hardhat_impersonateAccount", params: [mintingAddress],});
        var mintSigner = await ethers.getSigner(mintingAddress)
        
        await contract.connect(mintSigner).focusGeneration(1, 1).should.be.revertedWith('GenerationNotDowngradable')

        tokenUri = await contract.tokenURI(1);
        assert.equal(tokenUri.includes(`ipfs://generation-two/`), true);
    });

    it("Project owner cannot disable generation 2", async () => { 
        await contract.toggleGeneration(2).should.be.revertedWith('GenerationNotToggleable');
    });

    it("Can withdraw funds", async () => { 
        await contract.withdraw();
    });
})