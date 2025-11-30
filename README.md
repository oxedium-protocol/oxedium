![Solana](https://img.shields.io/badge/Blockchain-Solana-blue.svg)
![Anchor](https://img.shields.io/badge/Framework-Anchor-orange.svg)
![Flutter](https://img.shields.io/badge/Framework-Flutter-02569B.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)
![GitHub stars](https://img.shields.io/github/stars/oxedium-protocol/oxedium?style=social)


# Oxedium
Single-sided liquidity protocol on Solana

Earn trading fees **without impermanent loss** by depositing a single asset into Oxedium vaults.

---

## Why Oxedium?

Traditional AMMs require providing liquidity in pairs and expose users to impermanent loss.  
Oxedium allows you to earn from the growing Solana ecosystem **with a single asset**, making liquidity provision simpler, safer, and more profitable.

---

## Key Features

| Feature | Description |
|---------|-------------|
| **Balancer** | Automatically incentivizes traders to rebalance liquidity by depositing into deficit vaults and withdrawing from surplus vaults, providing the best rates across Solana. |
| **Slippage-Free Swaps** | Powered by Pyth price oracles for accurate and transparent pricing. |
| **Secure Vaults** | Vaults protected by internal reserves and automated circuit breakers to safeguard your funds. |

---

## How It Works

1. Deposit a single asset into a vault.
2. Traders rebalance vaults using the balancer mechanism.
3. Earn trading fees without worrying about impermanent loss.

> Join the existing flow of liquidity on Solana and extract yield from it effortlessly.

---

## Getting Started

1. Go to [oxedium.com](https://oxedium.com)
2. Connect your Solana wallet.
3. Select a vault.
4. Deposit your token and start earning fees.

---

## 🛠 Developer Integration

Oxedium Protocol exposes **4 Solana instructions** that can be called to interact with vaults and manage liquidity.  

### Available Instructions

1. **Staking** – deposit a token into a vault
```rust
pub struct StakingInstructionAccounts<'info> {
    #[account(mut)]
    pub signer: Signer<'info>,

    #[account(mut)]
    pub vault_mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [MINT_SEED.as_bytes(), vault_pda.key().as_ref()], 
        bump,
        mint::authority = treasury_pda.key(),
        mint::freeze_authority = treasury_pda.key()
    )]
    pub lp_mint: Account<'info, Mint>,

    #[account(mut, token::authority = signer, token::mint = vault_mint)]
    pub signer_ata: Account<'info, TokenAccount>,

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = lp_mint,
        associated_token::authority = signer,
    )]
    pub signer_lp_ata: Account<'info, TokenAccount>,

    #[account(mut, seeds = [VAULT_SEED.as_bytes(), &vault_mint.to_account_info().key.to_bytes()], bump)]
    pub vault_pda: Account<'info, Vault>,

    #[account(
        init_if_needed,
        payer = signer,
        seeds = [STAKER_SEED.as_bytes(), vault_pda.key().as_ref(), signer.key().as_ref()],
        bump,
        space = 8 + 32 + 32 + 16 + 8,
    )]
    pub staker_pda: Account<'info, Staker>,

    #[account(mut, seeds = [TYRBINE_SEED.as_bytes(), TREASURY_SEED.as_bytes()], bump)]
    pub treasury_pda: Account<'info, Treasury>,

    #[account(
        init_if_needed,
        payer = signer,
        associated_token::mint = vault_mint,
        associated_token::authority = treasury_pda,
    )]
    pub treasury_ata: Account<'info, TokenAccount>,

    pub associated_token_program: Program<'info, AssociatedToken>,
    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
}
```
2. **Unstaking** – withdraw from a vault - [How to call it?](https://github.com/oxedium-protocol/oxedium/blob/main/programs/tyrbine-program/src/instructions/staker/unstaking.rs#L54)
3. **Claim** – claim earned fees - [How to call it?](https://github.com/oxedium-protocol/oxedium/blob/main/programs/oxedium-program/src/instructions/staker/claim.rs#L43)
4. **Swap** – swap between vaults - [How to call it?](https://github.com/oxedium-protocol/oxedium/blob/main/programs/oxedium-program/src/instructions/trader/swap.rs#L130)

## Learn More

- [Whitepaper](https://xjx4fw67d3oyxf3nghsgyus2thdtexb26qrqpegmu5cbmxkkf7qa.arweave.net/um_C298e3YuXbTHkbFJamccyXDr0IweQzKdEFl1KL-A)
- [Twitter](https://x.com/tyrbine)
- [Telegram](https://t.me/oxedium_protocol)
