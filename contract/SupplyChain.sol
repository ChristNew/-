pragma solidity ^0.4.23;



contract SupplyChain {

  event RegisterEvent(int256 ret, address addr, uint amount);

  event OweEvent(int256 ret, address from, address to, uint amount);

  event TransferEvent(int256 ret, address x, address y, address z, uint amount);

  event FinanceEvent(int256 ret, address v, uint amount);

  event PaybackEvent(int256 ret, address from, address to, uint amount);



  struct Company {

    bool registered; // 判断公司是否注册

    address addr; // 公司公钥

    uint current_amount; // 现有资产

    uint debt_amount; // 债务总额

    uint bond_amount; // 债券总额

    mapping (address => uint) bond; // 谁欠你钱

    mapping (address => uint) debt; // 你欠谁钱

  }



  struct Receipt {

    address from; // 发起者

    address to;

    uint amount; // 资金变动

  }



  //uint public ratio; // 融资比例

  uint public company_num; // 公司总数

  mapping (address => Company) public companies;

  Receipt[] public receipts; // 收据数据库

  Company bank; // 第三方信任机构



  constructor () {

    bank.addr = 1;

    company_num = 1;

    companies[1] = bank;

    //ratio = 10;

  }



  function register(address addr, uint amount) public returns(bool) {

    if (companies[addr].registered == true) {

      emit RegisterEvent(-2, addr, amount); // 公司已经注册过了

      return false;

    }

    Company memory res = Company(true, addr, amount, 0, 0);

    companies[addr] = res;

    company_num++;

    emit RegisterEvent(0, addr, amount);

    return true;

  }



  // 签发应收账单 

  function owe(address from, address to, uint amount) public {

    if (companies[to].registered == false) { 

      emit OweEvent(-1, from, to, amount); // 债主不存在

      return;

    }

    companies[from].debt[to] += amount;

    companies[from].debt_amount += amount;



    companies[to].bond[from] += amount;

    companies[to].bond_amount += amount;



    receipts.push(Receipt(from, to, amount));



    emit OweEvent(0, from, to, amount);

  }



  // 应收帐单转让

  function transfer(address x, address y, address z, uint amount) public returns(bool) {

    if (companies[x].registered == false || companies[z].registered == false) {

      emit TransferEvent(-1, x, y, z, amount); // 公司不存在

      return false;

    }

    

    if (companies[x].debt[y] < amount || companies[y].debt[z] < amount) {

      emit TransferEvent(-2, x, y, z, amount); // 所欠金额小于转让金额

      return false;

    }



    companies[x].debt[y] -= amount;

    companies[x].debt[z] += amount;

    

    companies[y].bond[x] -= amount;

    companies[y].debt[z] -= amount;

    companies[y].bond_amount -= amount;

    companies[y].debt_amount -= amount;



    companies[z].bond[y] -= amount;

    companies[z].bond[x] += amount;



    receipts.push(Receipt(y, z, amount));

    receipts.push(Receipt(y, x, amount));



    emit TransferEvent(0, x, y, z, amount);

    return true;

  }



  // 利用应收账单向银行融资

  function finance(address v, uint amount) public returns(bool) {

    uint total_amount = companies[v].current_amount + companies[v].bond_amount - companies[v].debt_amount;

    

    if (amount > total_amount * 10) {

      emit FinanceEvent(-1, v, amount); // 融资额过高

      return false;

    }

    

    bank.bond[v] += amount; // 银行记录债务

    companies[v].debt[bank.addr] += amount; // 公司记录债务

    companies[v].current_amount += amount; // 公司现金增加

    

    receipts.push(Receipt(v, bank.addr, amount));



    emit FinanceEvent(0, v, amount); // 成功

    return true;

  }



  // 下游企业要求核心企业支付欠款（到期还钱）

  function payback(address from, address to, uint amount) public returns(bool) {



    if (companies[to].registered == false) {

      emit PaybackEvent(-1, from, to, amount); // 公司错误

      return false;

    }



    if (companies[to].debt[from] < amount) {

      emit PaybackEvent(-2, from, to, amount); // 索要金额大于所欠金额

      return false;

    }



    if (companies[to].current_amount < amount) {

      emit PaybackEvent(-3, from, to, amount); // 公司现金不够偿还债务

      return false;

    }



    companies[to].current_amount -= amount;

    companies[to].debt[from] -= amount;

    

    companies[from].current_amount += amount;

    companies[from].bond[to] -= amount;



    receipts.push(Receipt(from, to, amount));



    emit PaybackEvent(0, from, to, amount);

    return true;

  }

}



// Hub: 0xa108e66c69e967fda932f8850ee6e82d8a3ad461

// Wheel: 0xbd099b0ed95de6e96cf221cc60a34892679965ce

// bank: 0xc53cea54d416ab239466bbf323f2b972aaae239d

// BMW: 0xf89113bef85deb68a085854a11da81c6ddef19ca