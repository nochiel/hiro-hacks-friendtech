
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
;;

;; data vars
;;

;; data maps
(define-map keysBalance { subject: principal, holder: principal } uint)
(define-map keysSupply { subject: principal } uint)
;;

;; public functions
(define-public (buy-keys (subject principal) (amount uint))
    (let
        (
            (supply (get-keys-supply subject))
            (price (get-price supply amount))
        )
        (if (or (> supply u0) (is-eq tx-sender subject))        ;; a subject can always mint his own keys at cost.
            (begin
                (match (stx-transfer? price tx-sender
                        ;; Get this contract's principal i.e send the funds to the contract.
                        (as-contract tx-sender))
                    success
                    (begin
                        (map-set keysBalance { subject: subject, holder: tx-sender }
                            (+ (default-to u0
                                            (map-get? keysBalance { subject: subject, holder: tx-sender }))
                                amount))
                        (map-set keysSupply { subject: subject } (+ supply amount))
                        (ok true))
                    error
                        (err u2)))
            (err u1))))

;; Sell keys to the contract.
;; @audit Is it possible to drain the contract by manipulating prices.
;; i.e if the contract will always buy, then can we find a way to sell what we don't have?
(define-public (sell-keys (subject principal) (amount uint))
    (let
        ((balance (get-keys-balance subject tx-sender))
        (supply (get-keys-supply subject))
        (recipient tx-sender))

        (if (and (>= balance amount)
                 (or (> supply u0) (is-eq tx-sender subject)))  ;; principal can always mint more of their own tokens.
            (begin
                (match (as-contract (stx-transfer? price tx-sender recipient))
                    success
                    (begin
                        (map-set keysBalance { subject: subject, holder: tx-sender } (- balance amount))
                        (map-set keysSupply { subject: subject } (- supply amount))
                        (ok true))
                    error
                        (err u2)))
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
;;

;; private functions
;;

