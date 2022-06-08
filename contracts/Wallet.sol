//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract Wallet {

    // Соответствие релиза с ТЗ:

    // Отправка ETH:                            transferEthTo(address payable _to, uint _amount) external onlyOwner(_to)

    // Прием ETH:                               transferEthToOwner(uint _amount) public payable

    // Отправка Token:                          transferTokenTo(address payable _to, uint _amount) external onlyOwner(_to)

    // Прием Token:                             transferTokenToOwner(uint _amount) public

    // allowance для Token:                     function transferTokensFrom(address payable _to, uint _amount) external

    // allowance для ETH:                       transferEthFrom(address payable _to, uint _amount) external

    // Метод для изменения комиссии:            setFee(uint _percent_fee) external onlyOwner(msg.sender)

    // *** Дополнительные фичи: ***

    // Структура для хранения историй ETH переводов пользователей

    // Структура для хранения историй Token переводов пользователей

    // Структура для хранения ETH разрешений пользователей

    // Узнать баланс смарт-контракта (ETH):     currentBalance() public view returns(uint)
    
    // Узнать баланс смарт-контракта (Token):   currentTokenBalance() public view returns(uint)

    // Снять все средства смарт - контракта:    withdraw(address payable _to) external onlyOwner(_to)

    // Выдать разрешение на снятие ETH:         approve(address _to, uint amount) external onlyOwner(_to)

    // Выдать разрешение на снятие Token:       approveToken(address _to, uint _amount) external onlyOwner(_to)

    // Узнать разрешение на снятие ETH:         allowance() external view returns(uint)

    // Узнать разрешение на снятие Token:       allowanceToken() external view returns(uint)


    IERC20 public token;    // Токены стандарта ERC20

    address owner;          // Владелец контракта, тот кто может снимать все имеющиеся на контракте средства
                            // Может делать approve для отдельных адресов на фиксированную сумму

    // Адрес для приема комиссий, по ТЗ жестко закодирован в контракте
    // Тестовый из Remix IDE
    address for_fee = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;          


    uint private percent_fee;       // Процент комиссии вычисляется как (fee / 1000)

        // Конструктор контракта, принимает на вход значение комиссии и устанавливает его
        // Назначает владельца контракта
    constructor(uint _percent_fee) {
        require(_percent_fee < 1000, "Invalid fee current");
        owner = msg.sender;
        percent_fee = _percent_fee;
    }

        // Модификатор "Только для владельца", позволяет закрывать функциональность от посторонних
    modifier onlyOwner(address _to) {
        require(msg.sender == owner, "you are not an owner");
        require(_to != address(0), "incorrect address!");
        _;
    }

        // Функция для изменения размера комиссии
    function setFee(uint _percent_fee) external onlyOwner(msg.sender) {
        require(_percent_fee < 1000, "Invalid fee current");
        percent_fee = _percent_fee;
    }

        // Структура Платеж (ETH) пользователя
        // Размер перевода
        // Время перевода
        // Адрес отправителя перевода
    struct Payment {
        uint amount;
        uint timestamp;
        address from;
    }

        // Структура Платеж (Token) пользователя
        // Размер перевода
        // Время перевода
        // Адрес отправителя перевода
    struct TokenPayment {
        uint amount;
        uint timestamp;
        address from;
    }

        // Структура для учета выданных разрешений для ETH
        // amount - разрешенная сумма
        // sender - кем выдано разрешение (используется для проверки, что выдано владельцем)
    struct Approve {
        uint amount;
        address sender;
    }

        // Структура Баланс (ETH) пользователя 
        // Количество платежей полученных от пользователя
        // Список платежей {порядковый номер платежа ->  платеж}
    struct Balance {
        uint totalPayments;
        mapping(uint => Payment) payments;
    }

        // Структура Баланс (Token) пользователя 
        // Количество платежей полученных от пользователя
        // Список платежей {порядковый номер платежа ->  платеж}
    struct TokenBalance {
        uint totalPayments;
        mapping(uint => TokenPayment) tokenpayments;
    }

        // Введение зависимости {адрес клиента -> его баланс (ETH)}
    mapping(address => Balance) public balances;

        // Введение зависимости {адрес клиента -> его баланс (Token)}
    mapping(address => TokenBalance) public tokenbalances;

        // Введение зависимости {адрес клиента -> разрешенная для него сумма}
    mapping(address => Approve) public approves;

        // Узнать сумму средств на смарт-контракте (баланс (ETH) нашего кошелька)
    function currentBalance() public view returns(uint){
        return address(this).balance;
    }
    
       // Узнать сумму средств на смарт-контракте (баланс (Token) нашего кошелька)
    function currentTokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }

        // Узнать информацию о переводе (ETH) клиента по адресу и индексу
    function getPayment(address _addr, uint _index) external view returns(Payment memory){
        return balances[_addr].payments[_index];
    }
    
        // Узнать информацию о переводе (Token) клиента по адресу и индексу
    function getTokenPayment(address _addr, uint _index) external view returns(TokenPayment memory){
        return tokenbalances[_addr].tokenpayments[_index];
    }

        // Совершить перевод (ETH) на наш кошелек
        // Клиент должен прислать средств >= amount + fee, излишки к нему вернутся, в платежи учтется amount, fee учтется нам
    function transferEthToOwner(uint _amount) public payable {

        uint fee = _amount * (1000 - percent_fee) / 1000;   // Вычисление суммы комиссии

        require(msg.value >= _amount + fee, "The funds sent are not enough to deposit the entered amount, including the fee");

        uint paymentNum = balances[msg.sender].totalPayments; 
        balances[msg.sender].totalPayments++;

        Payment memory newPayment = Payment(
            _amount,
            block.timestamp,
            msg.sender
        );

        balances[msg.sender].payments[paymentNum] = newPayment;

        _amount += fee;

        payable(for_fee).transfer(fee); // Перечисление комиссии принимателю комиссий

        payable(msg.sender).transfer(msg.value - _amount); // Возврат излишков пользователю
        
    }

        // Совершить перевод (Token) на наш кошелек
    function transferTokenToOwner(uint _amount) public {

        require(token.allowance(msg.sender, address(this)) >= _amount, "You have not issued the required permission");

        token.transferFrom(msg.sender, address(this), _amount);     // Перевод токенов нам

        uint paymentNum = tokenbalances[msg.sender].totalPayments; 
        tokenbalances[msg.sender].totalPayments++;

        TokenPayment memory newPayment = TokenPayment(
            _amount,
            block.timestamp,
            msg.sender
        );

        tokenbalances[msg.sender].tokenpayments[paymentNum] = newPayment;  // Учет перевода пользователя
        
    }

        // Функция для отправления средств (ETH) на другой адрес без комиссии
        // Может использоваться только владельцем
    function transferEthTo(address payable _to, uint _amount) external onlyOwner(_to){
        require(address(this).balance >= _amount, "Not enough funds on the contract");
        _to.transfer(_amount);
    }

        // Функция для отправления средств (Token) на другой адрес без комиссии
        // Может использоваться только владельцем
    function transferTokenTo(address payable _to, uint _amount) external onlyOwner(_to){
        require(token.balanceOf(address(this)) >= _amount, "Not enough funds on the contract");
        token.transfer(_to, _amount);
    }

        // Функция чтобы снять все средства со смарт - контракта, может быть вызвана только владельцем
        // Средства отправятся на указанный адрес "_to"
    function withdraw(address payable _to) external onlyOwner(_to){
        _to.transfer(address(this).balance);
    }

        // Функция для выдачи разрешений адресу "_to" ETH в размере "amount"
        // Может быть вызвана только владельцем
    function approve(address _to, uint amount) external onlyOwner(_to){
        Approve memory newApprove = Approve(
            amount,
            msg.sender
        );
        approves[_to] = newApprove;
    }

        // Функция для выдачи разрешений адресу "_to" Token в размере "amount"
        // Может быть вызвана только владельцем
    function approveToken(address _to, uint _amount) external onlyOwner(_to){
        token.approve(_to, _amount);
    }

        // Функция для информирования пользователя о том сколько ETH ему доступно для вывода
    function allowance() external view returns(uint){
        address _to = msg.sender;
        return approves[_to].amount;
    }

        // Функция для информирования пользователя о том сколько Token ему доступно для вывода
    function allowanceToken() external view returns(uint){
        return token.allowance(address(this), msg.sender);
    }

        // Функция для снятия средств (ETH) пользователем, который имеет разрешение
        // Пользователь может снять эти средства на любой адрес, но функция должна быть вызвана тем, кому дано разрешение
        // Пользователь не может снять больше, чем ему позволено, оплата комиссии идет из указанной суммы снятия
    function transferEthFrom(address payable _to, uint _amount) external {
        uint fee = _amount * (1000 - percent_fee) / 1000;   // Вычисление суммы комиссии

        require(approves[_to].sender == owner, "Permission is invalid or does not exist");
        require(approves[_to].amount >= _amount, "You are trying to withdraw more than you are allowed to!");
        require(_to != address(0), "incorrect address!");
        _to.transfer(_amount - fee);
        approves[_to].amount -= _amount;
        payable(for_fee).transfer(fee); // Перечисление комиссии принимателю комиссий
    }

        // Функция для снятия средств (Token) пользователем, который имеет разрешение
        // Пользователь может снять эти средства на любой адрес, но функция должна быть вызвана тем, кому дано разрешение
        // Пользователь не может снять больше, чем ему позволено
    function transferTokensFrom(address payable _to, uint _amount) external {
        uint tokenBalance = token.balanceOf(address(this));

        require(token.allowance(address(this), msg.sender) > _amount, "You are trying to withdraw more than you are allowed to!");
        require(_to != address(0), "incorrect address!");
        require(_amount <= tokenBalance, "Not enough tokens in the reserve");
        token.transfer(_to, _amount);
    }

    // Функция для приема случайно переведенных средств, если кто-то переведет средства как на обычный кошелек
    // Заносится весь перевод кроме комиссии, комиссия отправляется приемщику комиссий
    receive() external payable {

        uint paymentNum = balances[msg.sender].totalPayments; 
        balances[msg.sender].totalPayments++;

        Payment memory newPayment = Payment(
            msg.value,
            block.timestamp,
            msg.sender
        );

        balances[msg.sender].payments[paymentNum] = newPayment;  // Учет перевода пользователя
    }
}



// Взято из открытого источника для реализации операций с Token

interface IERC20 {


    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);


    function transfer(address recipient, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);



    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}


// Для примера

contract ERC20Basic is IERC20 {


    string public constant name = "ERC20Basic";

    string public constant symbol = "ERC";

    uint8 public constant decimals = 18;



    mapping(address => uint256) balances;


    mapping(address => mapping (address => uint256)) allowed;


    uint256 totalSupply_ = 10 ether;



    constructor() {

        balances[msg.sender] = totalSupply_;

    }


    function totalSupply() public override view returns (uint256) {

        return totalSupply_;

    }


    function balanceOf(address tokenOwner) public override view returns (uint256) {

        return balances[tokenOwner];

    }


    function transfer(address receiver, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender]-numTokens;

        balances[receiver] = balances[receiver]+numTokens;

        emit Transfer(msg.sender, receiver, numTokens);

        return true;

    }


    function approve(address delegate, uint256 numTokens) public override returns (bool) {

        allowed[msg.sender][delegate] = numTokens;

        emit Approval(msg.sender, delegate, numTokens);

        return true;

    }


    function allowance(address owner, address delegate) public override view returns (uint) {

        return allowed[owner][delegate];

    }


    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {

        require(numTokens <= balances[owner]);

        require(numTokens <= allowed[owner][msg.sender]);


        balances[owner] = balances[owner]-numTokens;

        allowed[owner][msg.sender] = allowed[owner][msg.sender]-numTokens;

        balances[buyer] = balances[buyer]+numTokens;

        emit Transfer(owner, buyer, numTokens);

        return true;

    }

}
