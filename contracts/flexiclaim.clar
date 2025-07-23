;; --------------------------------------------------
;; Contract: claimdrop-plus
;; Purpose: Enhanced airdrop STX distribution with claim control
;; License: MIT
;; --------------------------------------------------

;; === Constants ===
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ALREADY_CLAIMED (err u101))
(define-constant ERR_NOT_ELIGIBLE (err u102))
(define-constant ERR_INSUFFICIENT_BALANCE (err u103))
(define-constant ERR_CLAIM_DEADLINE_PASSED (err u104))

;; === Admin Control ===
(define-data-var contract-owner principal tx-sender)

;; === Claimable STX Map ===
(define-map claimable-stx
  principal  ;; user
  uint       ;; amount
)

;; === Claim Status Map ===
(define-map has-claimed
  principal  ;; user
  bool       ;; true if already claimed
)

;; === Track Total Assigned ===
(define-data-var total-assigned uint u0)

;; === Claim Deadline (optional) ===
(define-data-var claim-deadline (optional uint) none) ;; block height

;; === Admin: Assign airdrop to one user ===
(define-public (set-claimable (user principal) (amount uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (map-set claimable-stx user amount)
    (var-set total-assigned (+ (var-get total-assigned) amount))
    (ok true)
  )
)

;; === Helper function for batch assignment ===
(define-private (batch-assign-helper (user-amt (tuple (user principal) (amt uint))) (acc bool))
  (let ((user (get user user-amt))
        (amt (get amt user-amt)))
    (begin
      (map-set claimable-stx user amt)
      (var-set total-assigned (+ (var-get total-assigned) amt))
      acc
    )
  )
)

;; === User: Claim STX ===
(define-public (claim)
  (let (
        (amount (default-to u0 (map-get? claimable-stx tx-sender)))
        (already-claimed (default-to false (map-get? has-claimed tx-sender)))
        (deadline (var-get claim-deadline))
        (current-block stacks-block-height)
       )
    (begin
      (asserts! (is-eq already-claimed false) ERR_ALREADY_CLAIMED)
      (asserts! (> amount u0) ERR_NOT_ELIGIBLE)
      (match deadline deadline-value
        (asserts! (<= current-block deadline-value) ERR_CLAIM_DEADLINE_PASSED)
        true)
      (try! (stx-transfer? amount (as-contract tx-sender) tx-sender))
      (map-set has-claimed tx-sender true)
      (map-delete claimable-stx tx-sender)
      (ok amount)
    )
  )
)

;; === Admin: Reclaim STX from unclaimed drop ===
(define-public (reclaim-unclaimed (user principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (let ((amount (default-to u0 (map-get? claimable-stx user)))
          (claimed (default-to false (map-get? has-claimed user))))
      (if (is-eq claimed false)
          (begin
            (map-delete claimable-stx user)
            (var-set total-assigned (- (var-get total-assigned) amount))
            (ok amount))
          (err u106)) ;; Already claimed, can't reclaim
    )
  )
)

;; === Admin: Set claim deadline (block height) ===
(define-public (set-claim-deadline (block uint))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set claim-deadline (some block))
    (ok true)
  )
)

;; === Admin: Withdraw unassigned STX ===
(define-public (withdraw-unused (amount uint) (recipient principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (stx-transfer? amount (as-contract tx-sender) recipient)
  )
)

;; === Admin: Transfer Ownership ===
(define-public (transfer-ownership (new-owner principal))
  (begin
    (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
    (var-set contract-owner new-owner)
    (ok true)
  )
)

;; === Read-Only: Check eligibility ===
(define-read-only (check-eligibility (user principal))
  (let (
        (amount (default-to u0 (map-get? claimable-stx user)))
        (claimed (default-to false (map-get? has-claimed user)))
       )
    (ok (and (> amount u0) (not claimed)))
  )
)

;; === Read-Only: Has user claimed? ===
(define-read-only (has-user-claimed (user principal))
  (ok (default-to false (map-get? has-claimed user)))
)

;; === Read-Only: Get contract owner ===
(define-read-only (get-owner)
  (ok (var-get contract-owner))
)

;; === Read-Only: Get claim deadline ===
(define-read-only (get-deadline)
  (ok (var-get claim-deadline))
)

;; === Read-Only: Get assigned total ===
(define-read-only (get-total-assigned)
  (ok (var-get total-assigned))
)
