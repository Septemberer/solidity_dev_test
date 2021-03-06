# Тестовая задача для Rock'n'Block

* Ссылка на смарт-контракт: **https://github.com/Septemberer/solidity_dev_test/blob/main/contracts/Wallet.sol**

## Тех.Задание:

* Возможность отправлять/принимать ETH
* Возможность отправлять/принимать токены
* Возможность делать allowance для токенов

### Добавить метод/функциональность для установки комиссии для переводов эфира:

* Должен присутствовать метод, изменяющий значение этой комиссии
* Комиссия представляет из себя какое-то число от переводимой суммы
* Адрес для перевода зашит в контракт хардкодом

___________________________________________________________

## Краткое описание реализованного:

* Отправка ETH: **transferEthTo**

* Прием ETH:   **transferEthToOwner**

* Отправка Token:  **transferTokenTo**

* Прием Token: **transferTokenToOwner**

* allowance для Token: **transferTokensFrom**

* allowance для ETH:   **transferEthFrom**

* Метод для изменения комиссии:    **setFee**

## Дополнительные фичи: ##

* Структура для хранения историй ETH переводов пользователей

* Структура для хранения историй Token переводов пользователей

* Структура для хранения ETH разрешений пользователей

* Узнать баланс (ETH) смарт-контракта:     **currentBalance**

* Узнать баланс (Token) смарт-контракта:   **currentTokenBalance**

* Снять все средства смарт - контракта:    **withdraw**

* Выдать разрешение на снятие ETH:         **approve**

* Выдать разрешение на снятие Token:       **approveToken**

* Узнать разрешение на снятие ETH:         **allowance**

* Узнать разрешение на снятие Token:       **allowanceToken**
* 
# Basic Sample Hardhat Project

This project demonstrates a basic Hardhat use case. It comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```
