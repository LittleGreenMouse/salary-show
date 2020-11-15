pragma solidity >=0.4.22 <0.8.0;
pragma experimental ABIEncoderV2;

contract SalaryShow {

    // 合约部署人
    address owner;

    // 用户列表
    address[] userList;
    // 数据列表
    bytes32[] dataList;

    // 根据用户address查找user
    mapping(address => User) user;
    // 根据数据id查找data
    mapping(bytes32 => Data) data;

    // 按行业查询薪资
    mapping(bytes32 => Industry) industrySalary;
    // 按公司查询薪资
    mapping(bytes32 => Company) companySalary;
    // 按职位查询薪资
    mapping(bytes32 => Position) positionSalary;

    struct User {
        // 用户地址
        address userAddr;

        // 用户名
        bytes32 name;

        // 密码
        bytes32 password;

        // 是否上传过薪资
        bool isUpload;

        // 薪资数据id
        bytes32 dataId;
    }

    struct Data {
        // 数据id
        bytes32 id;

        // 所属行业
        bytes32 industry;

        // 公司名称
        bytes32 company;

        // 职务
        bytes32 position;

        // 薪资
        uint salary;
    }

    struct Industry {
        // 行业
        bytes32 industry;

        // 本行业薪资数据的id
        bytes32[] dataIdList;

        // 总金额
        uint total;

        // 平均值
        uint average;
    }

    struct Company {
        // 公司
        bytes32 company;

        // 本公司薪资数据的id
        bytes32[] dataIdList;

        // 总金额
        uint total;

        // 平均值
        uint average;
    }

    struct Position {
        // 职位
        bytes32 position;

        // 本职位薪资数据的id
        bytes32[] dataIdList;

        // 总金额
        uint total;

        // 平均值
        uint average;
    }

    // 构造函数，设置合约部署者
    constructor(SalaryShow) public {
        owner = msg.sender;
    }

    // 只有部署者可以更新合约
    modifier restricted() {
        require(
            msg.sender == owner,
            "只有部署者可以更新合约"
        );
        _;
    }

    // 用户注册
    event NewUser(address sender, bool isSuccess, string message);
    function newUser(address _addr, string memory _name, string memory _password, string memory _dataId) public {
        if (isUserAlreadyRegister(_addr)) {
            emit NewUser(msg.sender, false, "用户已存在");
            return;
        } else {
            user[_addr].userAddr = _addr;
            user[_addr].name = stringToBytes32(_name);
            user[_addr].password = stringToBytes32(_password);
            user[_addr].isUpload = false;
            user[_addr].dataId = stringToBytes32(_dataId);

            userList.push(_addr);
            emit NewUser(msg.sender, true, "注册成功");
            return;
        }
    }

    // 登录时使用
    // 从用户地址获取用户密码
    function getUserPassword(address _addr) public view returns (bool, string memory) {
        if (isUserAlreadyRegister(_addr)) {
            return (true, bytes32ToString(user[_addr].password));
        } else {
            return (false, "");
        }
    }

    // 获取用户信息
    function getUserInfo(address _addr) public view returns (bool, address, string memory, bool, string memory) {
        if (isUserAlreadyRegister(_addr)) {
            address addr = user[_addr].userAddr;
            string memory name = bytes32ToString(user[_addr].name);
            bool isUpload = user[_addr].isUpload;
            string memory dataId = bytes32ToString(user[_addr].dataId);
            return (true, addr, name, isUpload, dataId);
        } else {
            return (false, _addr, "", false, "");
        }
    }

    // 上传薪资数据
    event UploadSalary(address sender, bool isSuccess, string message);
    function uploadSalary(address _addr, string memory _dataId, string memory _industry, string memory _company,
        string memory _position, uint _salary) public {
        if (isUserAlreadyRegister(_addr)) {
            bytes32 dataId = stringToBytes32(_dataId);
            bytes32 industry = stringToBytes32(_industry);
            bytes32 company = stringToBytes32(_company);
            bytes32 position = stringToBytes32(_position);

            // 更新薪资
            if (user[_addr].isUpload) {
                clearOldData(dataId);
            } else {
                // 首次上传
                dataList.push(dataId);
                user[_addr].isUpload = true;
            }

            // 写入薪资数据
            data[dataId].id = dataId;
            data[dataId].industry = industry;
            data[dataId].company = company;
            data[dataId].position = position;
            data[dataId].salary = _salary;

            // 按行业写入
            industrySalary[industry].industry = industry;
            industrySalary[industry].dataIdList.push(dataId);
            industrySalary[industry].total += _salary;
            industrySalary[industry].average = industrySalary[industry].total / industrySalary[industry].dataIdList.length;

            // 按公司写入
            companySalary[company].company = company;
            companySalary[company].dataIdList.push(dataId);
            companySalary[company].total += _salary;
            companySalary[company].average = companySalary[company].total / companySalary[company].dataIdList.length;

            // 按职位写入
            positionSalary[position].position = position;
            positionSalary[position].dataIdList.push(dataId);
            positionSalary[position].total += _salary;
            positionSalary[position].average = positionSalary[position].total / positionSalary[position].dataIdList.length;

            emit UploadSalary(msg.sender, true, "上传成功");
        } else {
            emit UploadSalary(msg.sender, false, "用户不存在");
        }
    }

    // 获取用户上传的薪资
    function getSalary(address _addr) public view returns (bool, string memory, string memory, string memory,
        string memory, uint) {
        if (isUserAlreadyRegister(_addr) && user[_addr].isUpload) {
            bytes32 dataId = user[_addr].dataId;

            string memory dataIdStr = bytes32ToString(dataId);
            string memory industry = bytes32ToString(data[dataId].industry);
            string memory company = bytes32ToString(data[dataId].company);
            string memory position = bytes32ToString(data[dataId].position);
            uint salary = data[dataId].salary;

            return (true, dataIdStr, industry, company, position, salary);
        } else {
            return (false, "", "", "", "", 0);
        }
    }

    // 获取行业薪资信息
    function getIndustrySalary(string memory _industry) public view returns (Industry memory) {
        bytes32 industry = stringToBytes32(_industry);
        return (industrySalary[industry]);
    }

    // 获取公司薪资信息
    function getCompanySalary(string memory _company) public view returns (Company memory) {
        bytes32 company = stringToBytes32(_company);
        return (companySalary[company]);
    }

    // 获取职位薪资信息
    function getPositionSalary(string memory _position) public view returns (Position memory) {
        bytes32 position = stringToBytes32(_position);
        return (positionSalary[position]);
    }

    // 判断用户是否已经注册过
    function isUserAlreadyRegister(address _addr) internal view returns (bool) {
        for (uint i = 0; i < userList.length; i++) {
            if (userList[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    // 更新薪资信息时删除旧薪资的统计信息
    function clearOldData(bytes32 _dataId) internal {
        bytes32 industry = data[_dataId].industry;
        bytes32 company = data[_dataId].company;
        bytes32 position = data[_dataId].position;
        uint salary = data[_dataId].salary;

        // 行业
        uint industryLen = industrySalary[industry].dataIdList.length;
        for (uint i = 0; i < industryLen; i++) {
            if (industrySalary[industry].dataIdList[i] == _dataId) {
                industrySalary[industry].dataIdList[i] = industrySalary[industry].dataIdList[industryLen - 1];
                industrySalary[industry].dataIdList.pop();

                if (industrySalary[industry].dataIdList.length != 0) {
                    industrySalary[industry].total -= salary;
                    industrySalary[industry].average = industrySalary[industry].total / industrySalary[industry].dataIdList.length;
                } else {
                    industrySalary[industry].total = 0;
                    industrySalary[industry].average = 0;
                }
                break;
            }
        }

        // 公司
        uint companyLen = companySalary[company].dataIdList.length;
        for (uint i = 0; i < companyLen; i++) {
            if (companySalary[company].dataIdList[i] == _dataId) {
                companySalary[company].dataIdList[i] = companySalary[company].dataIdList[companyLen - 1];
                companySalary[company].dataIdList.pop();

                if (companySalary[company].dataIdList.length != 0) {
                    companySalary[company].total -= salary;
                    companySalary[company].average = companySalary[company].total / companySalary[company].dataIdList.length;
                } else {
                    companySalary[company].total = 0;
                    companySalary[company].average = 0;
                }
                break;
            }
        }

        // 职位
        uint positionLen = positionSalary[position].dataIdList.length;
        for (uint i = 0; i < positionLen; i++) {
            if (positionSalary[position].dataIdList[i] == _dataId) {
                positionSalary[position].dataIdList[i] = positionSalary[position].dataIdList[positionLen - 1];
                positionSalary[position].dataIdList.pop();

                if (positionSalary[position].dataIdList.length != 0) {
                    positionSalary[position].total -= salary;
                    positionSalary[position].average = positionSalary[position].total / positionSalary[position].dataIdList.length;
                } else {
                    positionSalary[position].total = 0;
                    positionSalary[position].average = 0;
                }
                break;
            }
        }
    }

    // string转bytes32
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    // bytes32转string
    function bytes32ToString(bytes32 x) internal pure returns (string memory result) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}
