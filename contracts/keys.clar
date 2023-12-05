
;; title: keys
;; version:
;; summary: A clone of https://friend.tech for the 2023-12 Hiro Hacks
;; description: FriendTech
;; Refer to https://basescan.org/address/0xcf205808ed36593aa40a44f10c7f7c2f67d4a4d4#code

;; traits
;;

;; token definitions
;;

;; constants

;; For Access Control refer to https://github.com/clarity-lang/book/blob/main/projects/multisig-vault/contracts/multisig-vault.clar
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
;;

;; data vars
(define-data-var protocolFeeFactor uint u500)   ;; .2%
(define-data-var subjectFeeFactor uint u300)    ;; .3%
;; The default protocol fee destination is the creator of the contract.
;; @findout How do I set a different destination at deployment?
;; @audit Who can set protocolFeeDestination?
(define-data-var protocolFeeDestination principal tx-sender)
;;

;; data maps
(define-map keysBalance { subject: principal, holder: principal } uint)
(define-map keysSupply { subject: principal } uint)
;;

;; public functions

;; @todo
(define-public (set-protocol-fee-percent (feePercent uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set protocolFeeFactor feePercent))))

(define-public (set-subject-fee-percent (feePercent uint))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (ok (var-set subjectFeeFactor feePercent))))

(define-public (set-protocol-fee-destination (destination principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; @audit Do we need to assert! that the address is non-zero?
        (asserts! (is-standard destination) (err u404))
        (ok (var-set protocolFeeDestination destination))))

(define-public (buy-keys (subject principal) (amount uint))
    (let
        ((supply (get-keys-supply subject))
        (price (get-buy-price subject amount))
        (protocolFee (/ price (var-get protocolFeeFactor)))
        (subjectFee (/ price (var-get subjectFeeFactor)))
        ;; (priceAfterFees (+ price protocolFee subjectFee))
        )
        ;; The subject can always mint his own keys at cost.
        (if (or (> supply u0) (is-eq tx-sender subject))
            (begin
                (try! (stx-transfer? price tx-sender (as-contract tx-sender))) ;; as-contract gets this contract's principal i.e send the funds to the contract.
                (try! (stx-transfer? protocolFee tx-sender (var-get protocolFeeDestination)))
                (try! (stx-transfer? subjectFee tx-sender subject))
                (map-set keysBalance { subject: subject, holder: tx-sender }
                        (+ (default-to u0
                                (map-get? keysBalance { subject: subject, holder: tx-sender }))
                            amount))
                (map-set keysSupply { subject: subject } (+ supply amount))
                (ok true))
            (err u1))))

;; Sell keys to the contract.
;; @audit Is it possible to drain the contract by manipulating prices.
;; i.e if the contract will always buy, then can we find a way to sell what we don't have?
(define-public (sell-keys (subject principal) (amount uint))
    (let
        ((balance (get-keys-balance subject tx-sender))
            (supply (get-keys-supply subject))
        (price (get-sell-price subject amount))
        (protocolFee (/ price (var-get protocolFeeFactor)))
        (subjectFee (/ price (var-get subjectFeeFactor)))
        (priceMinusFees (- price protocolFee subjectFee))
        (recipient tx-sender))

        (if (and (>= balance amount)
                 (or (> supply u0) (is-eq tx-sender subject)))  ;; principal can always mint more of their own tokens.
            (begin
                (try! (as-contract (stx-transfer? price tx-sender recipient)))  ;; This contract pays the seller.
                ;; The seller pays fees.
                (try! (stx-transfer? protocolFee recipient (var-get protocolFeeDestination)))
                (try! (stx-transfer? subjectFee recipient subject))
                (map-set keysBalance { subject: subject, holder: tx-sender } (- balance amount))
                (map-set keysSupply { subject: subject } (- supply amount))
                (ok true))
            (err u1))))
;;

;; read only functions
(define-read-only (get-price (supply uint) (amount uint))
    (let
        (
            (base-price u10)
            (price-change-factor u100)
            (adjusted-supply (+ supply amount))
        )
        ;; price = (price_base + (amount * adjusted_supply ^ 2) / price_change_factor)
        ;; y     = (x^2)/k + b
        ;;       = mx^2 + b
        (+ base-price (* amount (/ (* adjusted-supply adjusted-supply) price-change-factor)))))

(define-read-only (is-keyholder (subject principal) (holder principal))
    (>= (default-to u0 (map-get? keysBalance { subject: subject, holder: holder }))
        u1))

(define-read-only (get-keys-balance (subject principal) (holder principal))
    ;; Return the keysBalance for the given subject and holder.
    (default-to u0 (map-get? keysBalance { subject: subject, holder: holder})))

(define-read-only (get-keys-supply (subject principal))
    ;; Return the keysSupply for the given subject
    (default-to u0 (map-get? keysSupply { subject: subject })))

(define-read-only (get-buy-price (subject principal) (amount uint))
    (let
        ((supply (default-to u0 (map-get? keysSupply {subject: subject }))))
        (get-price supply amount)))

(define-read-only (get-sell-price (subject principal) (amount uint))
    (let
        ((supply (default-to u0 (map-get? keysSupply {subject: subject }))))
        ;; Selling always gets a lower price than buying the equivalent amount.
        (get-price (- supply amount) amount)))

;;

;; private functions
;;

