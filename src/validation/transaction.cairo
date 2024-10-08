//! Transaction validation helpers.

use crate::types::transaction::Transaction;

/// Validate transaction and return transaction fee.
///
/// This does not include script checks and outpoint inclusion verification.
pub fn validate_transaction(
    tx: @Transaction, block_height: u32, block_time: u32
) -> Result<u64, ByteArray> {
    // TODO: validate that
    //      - Inputs array is not empty
    //      - Outputs array is not empty
    //      - Output values are within the range [0, 21M]
    //      - Total output value is within the range [0, 21M]
    //      - Transaction fee is in the range [0, 21M]
    //      - Tranaction weight is less than the max block weight (consider adding a weight method
    //      to the Encode trait)
    //        read more https://learnmeabitcoin.com/technical/transaction/size/
    //      - Transaction is final (check timelock and input sequences)
    //      - Coinbase is mature (if some input spends coinbase tx from the past)
    //
    //  Skipped checks:
    //      - There are no duplicate inputs - this should be actually done during the Utreexo proof
    //      verification - Maybe we don't need to check the upper money range (21M)
    //
    // References:
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_check.cpp
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/consensus/tx_verify.cpp
    //      - https://github.com/bitcoin/bitcoin/blob/master/src/validation.cpp

    let mut total_input_amount = 0;
    for input in *tx.inputs {
        total_input_amount += *input.previous_output.data.value;
    };

    let mut total_output_amount = 0;
    for output in *tx.outputs {
        total_output_amount += *output.value;
    };

    if total_output_amount > total_input_amount {
        return Result::Err(
            format!(
                "[validate_transaction] negative fee (output {total_output_amount} > input {total_input_amount})"
            )
        );
    }
    let tx_fee = total_input_amount - total_output_amount;

    Result::Ok(tx_fee)
}

#[cfg(test)]
mod tests {
    use crate::types::transaction::{Transaction, TxIn, TxOut, OutPoint};
    use crate::utils::hex::from_hex;
    use super::{validate_transaction};

    #[test]
    fn test_tx_fee() {
        let tx = Transaction {
            version: 1,
            is_segwit: false,
            inputs: array![
                TxIn {
                    script: @from_hex(
                        "01091d8d76a82122082246acbb6cc51c839d9012ddaca46048de07ca8eec221518200241cdb85fab4815c6c624d6e932774f3fdf5fa2a1d3a1614951afb83269e1454e2002443047"
                    ),
                    sequence: 0xffffffff,
                    previous_output: OutPoint {
                        txid: 0x0437cd7f8525ceed2324359c2d0ba26006d92d856a9c20fa0241106ee5a597c9_u256
                            .into(),
                        vout: 0x00000000,
                        data: TxOut { value: 100, ..Default::default() },
                        block_height: Default::default(),
                        block_time: Default::default(),
                    },
                    witness: array![].span(),
                }
            ]
                .span(),
            outputs: array![
                TxOut {
                    value: 90,
                    pk_script: @from_hex(
                        "ac4cd86c7e4f702ac7d5debaf126068a3b30b7c1212c145fdfa754f59773b3aae71484a22f30718d37cd74f325229b15f7a2996bf0075f90131bf5c509fe621aae0441"
                    ),
                    cached: false,
                }
            ]
                .span(),
            lock_time: 0
        };

        let fee = validate_transaction(@tx, 0, 0).unwrap();
        assert_eq!(fee, 10);
    }
}
