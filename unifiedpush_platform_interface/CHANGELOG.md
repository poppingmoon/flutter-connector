## 3.1.0
* Add PushEndpoint.temporary, to be able to ignore new endpoint from fallback distributors, when the primary distrib is down
* Add optional initializeOnTempUnavailable function

## 3.0.1

**Breaking**:
* Process PushEndpoint/PushMessage, to get public keys informations and auto decrypt push messages
* Rename registerApp => register

**New**:
* Add VAPID
* Add tryUseCurrentOrDefaultDistributor, to use the system default distributor
* Add sedDBusName for linux

## 2.0.2
* Add link to repository
* Move depencency\_validator to dev\_dependencies

## 2.0.1
* Upgrade max sdk

## 2.0.0
* getDistributor returns nullable string

## 1.0.0
* Use a platform interface

