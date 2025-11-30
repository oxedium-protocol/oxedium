use anchor_lang::prelude::*;
use crate::{states::{Vault, Treasury}, utils::TyrbineError};

pub fn check_admin(treasury_pda: &Treasury, signer: &Signer) -> Result<()> {
    if signer.key() != treasury_pda.admin {
        return Err(TyrbineError::InvalidAdmin.into());
    }
    
    Ok(())
}

pub fn check_stoptap(vault: &Vault, treasury_pda: &Treasury) -> Result<()> {
    if !vault.is_active {
        return Err(TyrbineError::StoptapActivated.into());
    }

    if treasury_pda.stoptap {
        return Err(TyrbineError::StoptapActivated.into());
    }
    
    Ok(())
}