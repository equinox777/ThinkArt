import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:think_art/Pages/deposit.dart';
import 'package:think_art/authentication.dart';
import 'package:web3dart/web3dart.dart';

class Profile extends StatefulWidget {
  @override
  _ProfileState createState() => _ProfileState();
}

var coinsRemaining;
int myAmount = 0;

class _ProfileState extends State<Profile> {
  Client httpClient;
  Web3Client ethClient;
  bool data = false;
  final myAddress = "0x20B85673252CAb8D906C11C69Ac85b6122794b8d";
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    httpClient = Client();
    ethClient = Web3Client("https://rpc-mumbai.matic.today", httpClient);
    getBalance(myAddress);
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/abi.json");
    String contractAddress = "0xeA5F86c31dBCe98d10b62529d328b206190756C9";
    final contract = DeployedContract(ContractAbi.fromJson(abi, "TAZcoin"),
        EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
        contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance(String targetaddress) async {
    EthereumAddress address = EthereumAddress.fromHex(targetaddress);
    List<dynamic> result = await query("getBalance", []);
    coinsRemaining = result[0];
    setState(() {
      data = true;
    });
  }

  Future<String> submit(String functionName, List<dynamic> args) async {
    EthPrivateKey credentials = EthPrivateKey.fromHex(
        "a9bf134facdd642a02e1f6e008cb21901e28952c0541df466e76cb8cda3ed296");
    DeployedContract contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.sendTransaction(
        credentials,
        Transaction.callContract(
            contract: contract, function: ethFunction, parameters: args),
        fetchChainIdFromNetworkId: true);
    return result;
  }

  Future<String> sendCoin() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("depositBalance", [bigAmount]);
    print("Deposited");
    return response;
  }

  Future<String> withdrawCoin() async {
    var bigAmount = BigInt.from(myAmount);
    var response = await submit("withdrawBalance", [bigAmount]);
    print("Withdrawn");
    return response;
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    return Container(
      width: width,
      height: height,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(width, height),
            painter: CurvePainter(),
          ),
          Padding(
            padding: EdgeInsets.only(left: width * 0.07, top: height * 0.19),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.orange,
                  radius: width * 0.1,
                ),
                SizedBox(
                  width: 20,
                ),
                Text(
                  email,
                  style: TextStyle(fontSize: width * 0.05, color: Colors.white),
                )
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
                left: (width * 0.15), top: height * 0.19 + width * 0.1),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(shape: CircleBorder()),
              onPressed: () {
                // PARTH WRITE YOUR CODE HERE TO CHANGE THE PROFILE PIC
              },
              child: Icon(Icons.camera_alt),
            ),
          ),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(left: width * 0.07),
                child: RichText(
                    text: TextSpan(children: [
                  TextSpan(
                      text: "Coins Remaining\n\n",
                      style: TextStyle(
                          color: Colors.red[400],
                          fontSize: width * 0.07,
                          fontWeight: FontWeight.bold)),
                  TextSpan(
                      text: ' TAZ ' + coinsRemaining.toString(),
                      style: TextStyle(
                          color: Colors.red[400],
                          fontSize: width * 0.05,
                          fontWeight: FontWeight.w700))
                ])),
              )),
          Padding(
            padding: EdgeInsets.only(top: height * 0.35),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.red[400],
                          elevation: 8,
                          shadowColor: Colors.red[200],
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)))),
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => Deposit()));
                      },
                      child: Container(
                          width: 100,
                          height: 50,
                          child: Center(child: Text("Deposit"))),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          primary: Colors.red[400],
                          elevation: 8,
                          shadowColor: Colors.red[200],
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)))),
                      onPressed: () {
                        setState(() {
                          getBalance(myAddress);
                        });
                      },
                      child: Container(
                          width: 100,
                          height: 50,
                          child: Center(child: Text("Refresh"))),
                    ),
                  ],
                ),
                SizedBox(height: width * 0.08),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      primary: Colors.red[400],
                      elevation: 8,
                      shadowColor: Colors.red[200],
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15)))),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await FirebaseAuth.instance.signOut();
                    prefs.setString('think_art_email', '');
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Authentication()));
                  },
                  child: Container(
                      width: 100,
                      height: 50,
                      child: Center(child: Text("Logout"))),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    paint.color = Colors.white.withOpacity(0.8);
    paint.style = PaintingStyle.fill;

    var path = Path();

    path.moveTo(0, size.height * 0.3);
    path.lineTo(0, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, size.height * 0.45);
    // path.moveTo(0, size.height);
    // path.lineTo(size.width, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
