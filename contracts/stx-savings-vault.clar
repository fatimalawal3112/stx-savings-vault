;; ---------------------------------------------------
;; STX Savings Vault Smart Contract
;; Users can deposit STX and lock it until maturity.
;; Early withdrawal is NOT allowed.
;; ---------------------------------------------------

(define-map vaults
  principal
  {
    amount: uint,
    unlock-block: uint
  }
)

;; ---------------------------------------------------
;; Deposit STX into the vault
;; lock-period = number of blocks to lock funds
;; ---------------------------------------------------
(define-public (deposit (lock-period uint) (amount uint))
  (begin
    (asserts! (> amount u0) (err u100)) ;; amount must be > 0
    (asserts! (> lock-period u0) (err u101)) ;; must lock for >0 blocks

    ;; transfer funds to contract
    (try! (stx-transfer? amount tx-sender (as-contract tx-sender)))

    ;; store vault info
    (map-set vaults tx-sender {
      amount: amount,
      unlock-block: (+ burn-block-height lock-period)
    })
    (ok true)
  )
)

;; ---------------------------------------------------
;; Withdraw funds after maturity
;; ---------------------------------------------------
(define-public (withdraw)
  (let ((vault (map-get? vaults tx-sender)))
    (match vault
      vault-data
        (if (>= burn-block-height (get unlock-block vault-data))
          (begin
            (map-delete vaults tx-sender)
            (stx-transfer? (get amount vault-data) (as-contract tx-sender) tx-sender)
          )
          (err u102) ;; not matured yet
        )
      (err u103) ;; no vault found
    )
  )
)

;; ---------------------------------------------------
;; Check vault details
;; ---------------------------------------------------
(define-read-only (get-vault (user principal))
  (map-get? vaults user)
)
