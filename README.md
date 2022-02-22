# A Non-Dilutive 721 Utilizing Mimetic Metadata (Off-Chain Version)

* Note: This code is unaudited and a work of a midnight conversation. There does exist the ability to do this with on-chain metadata in a far more robust way. Coming soon.

## Foreword

This token was created to serve as a proof for a conversational point. Doodles is dropping Space Doodles with the marketing that they are non-dilutive. This is nothing more than quite flimsy marketing built on half-accuracies.

![The Space Doodles drop](https://pbs.twimg.com/media/FIln4NFWQAYqyWi?format=jpg&name=4096x4096)

Unfortunately, holders will funnel into this and the market will soon experience a cycle where buyers are constantly buying wrapped tokens thinking they're non-dilutive. Meanwhile, the markets will continue to go down and people will wonder why... This is why. Unfortunately, many will perceive this type of launch as genuinely non-dilutive as the argument of collectability will be hammered into the minds of holders and market participants. Congratulations, successfully allowed yet another "Blue Chip" team to force holders into a Ponzi that is going to be protected as their bags now depend on it.

The blind leading the blind. 

This repository proposes a different solution. Doodles is an NFT that simply points to off-chain metadata. So, this repository follows in that model to maintain the highest of conversational relevance.

What I am proposing is Mimetic Metadata:

![Mimetic metadata](https://i.imgur.com/znXXJwS.png)

Essentially, with Mimetic Metadata we stop printing new tokens and instead pack the metadata within the same token. All within the control of the holder and project owner without a single massive downside beyond the project creators no longer releasing an asinine amount of tokens into their ecosystem.

>  The extendable 'Generations' wrap the token metadata within the content to remove the need  of dropping another token into the collection. By doing this, that does not inherently mean the metadata is mutable beyond the extent that the token holder can change the active metadata. The underlying generations still much exist and can be configured in a  way that allows accessing them again if desired. However, there does also exist the  ability to have truly immutable layers that cannot be removed. (If following this implementation it is vitally noted that object permanence must be achieved from day one. A project CANNOT implement this on a mutable URL that is massive holder-trust betrayal.)


## Implementation Documentation

This contract has been built to perfectly illustrate that absolutely no sacrifices are made when implementing this structure. Meanwhile, the holders and project owners gain and incredible amount of security and maintainbility.

Please note, Mimetic Metadata is not created in effort to get projects in a position where they need release another collection. Rather, it should be strategically done that doesn't put their holders "value" in direct danger. With Mimetic Metadata it is simplest to perceive tokens as Avatars. If the addition of the project is not a pivotal piece to the already existing Avatar (that walks or talks) then it potentially does make sense to have a new collection.

Such as:

* Doodle Spaceships belong in the same collection.

* Doodle pets/children belong in a different collection.

### When deploying

The base layer is automatically generated just like a typical NFT contract that you are used to seeing. This layer cannot be disabled, the URI is immutable and holders cannot remove it from their token. This means that a permanent storage solution must be acquired (Whooo more holder security!)

1. Update max supply that can be minted.
2. Update mint cost.
3. Deploy with constructor args.

### When minting

Runs just like normal. Have the ability to implement standard reveal functions such as Chainlink VRF to automatically generate an offset to the image used. This is kind of a hacky solution and a less than ideal solution. Realistically, it would be a lower barrier of entry to have a reveal mechanism built in however this has reached the extent of my midnight jam. Submit a PR.

1. Set mint as open.

### When adding functionality

We now run through the primary contract instead of deploying a new contract that focuses on funneling our holders and their money into an entirely new collection. Yuck! Instead, we will be adding the update within the base contract. This means that everything will update within the primary collection and it is truly non-dillutive of all aspects! Finally, holders are not punished as builders, build.

1. Load the generation.
2. Enable the generation to allow for token evolution.

#### Loading a generation

| Type        | Option                   | Values          | Notes                                             |
|-------------|--------------------------|-----------------|---------------------------------------------------|
| bool        |    loaded                | (true, false)   | Prevents the detachment                           |
| bool        |    enabled               | (true, false)   | Prevents premature holder connection              |
| bool        |    locked                | (true, false)   | Makes generation contract-level immutable         |    
| bool        |    sticky                | (true, false)   | Makes generation holder-level immutable           |    
| uint256     |    cost                  | (0 -> x - 1)    | The one-time cost of generation access            |
| uint256     |    evolutionClosure      | (0 -> x - 1)    | If zero, infinite time to claim.                  |
| string      |    baseURI               | ipfs://..       | The off-chain URI of the metadata                 |
| uint256     |    top                   | (0 -> x - 1)    | The top token that has been revealed              |
| uint256     |    offset                | (0 -> x - 1)    | The baseToken offset of the generation metadata   | 
 
Beyond that, you should be able to walk yourself the rest of the way through it. This code is not exceptionally complicated. Just steal the code and implement it into the market please. We seriously cannot allow Doodles to spread this falsehood so far that it brings us into a new cycle. With that, enough talk already, can we just run the code...

### When revealing

In the base of the contract lies a baseUnrevealedURI which is used any time a token is in the evolution state before a generation has been revealed. This has been made to be constant through all generations as it is kind of wasteful and doesn't change anything beyind aesthetic preference which is not extremely powerful while in the context of this conversation.

Note: This has been placed at the bottom of the documentation however there may be instances in which a project prefers to reveal before the sale even starts. That is entirely supported.

1. Set top revealed token

## Running The Project

Running the tests for the project is very simple. Combined with the in-contract documentation you should have everything you need to get rolling. Finally, you too can create a truly non-dilutive NFT collection.

1. Copy example.env to .env and enter values.
2. Use shell commands below:

```shell
npm i
npx hardhat test
```

## Author Note

Inside the contract every function has been documented so that you can follow along with what is going on. As Doodles are released people are going to say that it is non-dilutive. They are incorrect. This here, is the implementation of what a non-dilutive token drop would actually look like. However, please do note that if I believed this to be the best implementation I would have already done it ;) This is not an opinion of mine rather an attempt to serve as an outlet for market transparency and honesty.

Non-dilutive 721 tokens can exist. Teams can easily build around this concept. Teams can additionally  still monetize the going ons and hard work of their team. However, that does not need to come at the cost of their holders. As it stands every token drop following the initial is a holder mining experience in which every single holders is impacted by the lower market concentration of liquidty and attention.

I didn't bother optimizing the base 721 contract nor any of the primary functionality. Readability > gas in this case as this is not a repository I will be launching and instead is purely a conversational/open-source option that you can utilize.

If this actually ends up being seen by more than 5 people I'll update that.

## Infographic

![Infographic of implementation](https://i.imgur.com/5MXG0Wy.png)