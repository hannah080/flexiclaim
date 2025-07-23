# FlexiClaim Smart Contract

A flexible STX distribution contract built on Stacks blockchain that enables controlled token distribution with claiming mechanisms.

## Features

- 🔒 Admin-controlled STX distribution
- ⏰ Configurable claim deadline
- 👥 Individual and batch assignment support
- 💰 Reclaim functionality for unclaimed amounts
- 🔄 Ownership transfer capabilities
- 📊 Comprehensive status tracking

## Contract Functions

### Admin Functions

```clarity
(set-claimable (user principal) (amount uint))
(reclaim-unclaimed (user principal))
(set-claim-deadline (block uint))
(withdraw-unused (amount uint) (recipient principal))
(transfer-ownership (new-owner principal))
```

### User Functions

```clarity
(claim)
```

### Read-Only Functions

```clarity
(check-eligibility (user principal))
(has-user-claimed (user principal))
(get-owner)
(get-deadline)
(get-total-assigned)
```

## Error Codes

- `ERR_UNAUTHORIZED (u100)`: Caller is not the contract owner
- `ERR_ALREADY_CLAIMED (u101)`: User has already claimed their tokens
- `ERR_NOT_ELIGIBLE (u102)`: User is not eligible for claiming
- `ERR_INSUFFICIENT_BALANCE (u103)`: Contract has insufficient balance
- `ERR_CLAIM_DEADLINE_PASSED (u104)`: Claim deadline has passed

## Usage

1. Deploy the contract
2. Set claim deadline (optional)
3. Assign STX to users
4. Users can claim their allocated STX before deadline
5. Admin can reclaim unclaimed amounts


### Testing

```bash
clarinet test
```

## Security

- Admin-only functions are protected with authorization checks
- Double-claim prevention
- Deadline enforcement
- Safe STX transfer handling

