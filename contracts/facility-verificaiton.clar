;; Facility Verification Contract
;; Validates production sites in the manufacturing network

(define-data-var admin principal tx-sender)

;; Facility status: 0 = unverified, 1 = verified, 2 = suspended
(define-map facilities
  { facility-id: (string-utf8 36) }
  {
    owner: principal,
    name: (string-utf8 100),
    location: (string-utf8 100),
    status: uint,
    verification-date: uint
  }
)

(define-read-only (get-facility (facility-id (string-utf8 36)))
  (map-get? facilities { facility-id: facility-id })
)

(define-public (register-facility
    (facility-id (string-utf8 36))
    (name (string-utf8 100))
    (location (string-utf8 100))
  )
  (let ((existing-facility (get-facility facility-id)))
    (asserts! (is-none existing-facility) (err u1)) ;; Facility ID already exists
    (ok (map-set facilities
      { facility-id: facility-id }
      {
        owner: tx-sender,
        name: name,
        location: location,
        status: u0, ;; Initially unverified
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-facility (facility-id (string-utf8 36)))
  (let ((existing-facility (get-facility facility-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (is-some existing-facility) (err u3)) ;; Facility not found
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge (unwrap-panic existing-facility)
        {
          status: u1, ;; Set to verified
          verification-date: block-height
        }
      )
    ))
  )
)

(define-public (suspend-facility (facility-id (string-utf8 36)))
  (let ((existing-facility (get-facility facility-id)))
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (asserts! (is-some existing-facility) (err u3)) ;; Facility not found
    (ok (map-set facilities
      { facility-id: facility-id }
      (merge (unwrap-panic existing-facility)
        { status: u2 } ;; Set to suspended
      )
    ))
  )
)

(define-public (transfer-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender (var-get admin)) (err u2)) ;; Not admin
    (ok (var-set admin new-admin))
  )
)
