import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import 'package:web_socket_channel/web_socket_channel.dart'; 

class ContractLinking extends ChangeNotifier {
  
  // Configuration Ganache
  final String _rpcUrl = "http://127.0.0.1:7545";
  final String _wsUrl = "ws://127.0.0.1:7545/";

  // VOTRE CLÉ PRIVÉE (Celle copiée de Ganache)
  final String _privateKey = "0x924743ecdb5c47a1c7ed2dc2d5c36312e0296f0f01924343e63fd8ffbdbdf216"; 

  late Web3Client _client;
  bool isLoading = true;
  
  late String _abiCode;
  late EthereumAddress _contractAddress;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _yourName;
  late ContractFunction _setName;
  
  String deployedName = "";
  late int _networkId;

  ContractLinking() {
    initialSetup();
  }

  initialSetup() async {
    _client = Web3Client(_rpcUrl, Client(), socketConnector: () {
      return WebSocketChannel.connect(Uri.parse(_wsUrl)).cast<String>();
    });

    // 1. On détecte le VRAI ID du réseau (ex: 5777)
    _networkId = await _client.getNetworkId();
    print("Network ID détecté par le client : $_networkId");

    await getAbi();
    await getCredentials();
    await getDeployedContract();
  }

  Future<void> getAbi() async {
    String abiStringFile = await rootBundle.loadString("src/artifacts/HelloWorld.json");
    var jsonAbi = jsonDecode(abiStringFile);
    _abiCode = jsonEncode(jsonAbi["abi"]);

    Map<String, dynamic> networks = jsonAbi["networks"];
    
    // --- CORRECTION INTELLIGENTE ---
    // On cherche d'abord l'adresse qui correspond EXACTEMENT à notre Ganache (_networkId)
    String networkIdString = _networkId.toString();
    
    if (networks.containsKey(networkIdString)) {
      String address = networks[networkIdString]["address"];
      print("Parfait ! Adresse trouvée pour le réseau $networkIdString : $address");
      _contractAddress = EthereumAddress.fromHex(address);
    } else {
      // Si on ne trouve pas, on prend la première disponible (Secours)
      String fallbackKey = networks.keys.first;
      String address = networks[fallbackKey]["address"];
      print("ATTENTION : Adresse non trouvée pour $networkIdString. Utilisation du réseau $fallbackKey : $address");
      _contractAddress = EthereumAddress.fromHex(address);
    }
  }

  Future<void> getCredentials() async {
    // Nettoyage de la clé (au cas où il y ait des espaces)
    String cleanKey = _privateKey.trim();
    _credentials = EthPrivateKey.fromHex(cleanKey);
  }

  Future<void> getDeployedContract() async {
    _contract = DeployedContract(ContractAbi.fromJson(_abiCode, "HelloWorld"), _contractAddress);
    _yourName = _contract.function("yourName");
    _setName = _contract.function("setName");
    getName();
  }

  getName() async {
    try {
      // Appel en lecture
      var currentName = await _client.call(contract: _contract, function: _yourName, params: []);
      deployedName = currentName[0];
      print("Nom récupéré : $deployedName");
      isLoading = false;
      notifyListeners();
    } catch (e) {
      print("Erreur getName (Probablement mauvaise adresse contrat): $e");
      isLoading = false;
      notifyListeners();
    }
  }

  setName(String nameToSet) async {
    isLoading = true;
    notifyListeners();
    try {
      await _client.sendTransaction(
        _credentials,
        Transaction.callContract(
          contract: _contract, 
          function: _setName, 
          parameters: [nameToSet]
        ),
        // CORRECTION TRANSACTION : Ganache veut souvent 1337 pour signer, même sur le réseau 5777
        chainId: 1337 
      );
      getName();
    } catch (e) {
      print("Erreur setName: $e");
      
      // Si 1337 échoue, on réessaie automatiquement avec l'ID détecté (5777)
      print("Tentative avec l'ID détecté $_networkId...");
      try {
         await _client.sendTransaction(
          _credentials,
          Transaction.callContract(
            contract: _contract, function: _setName, parameters: [nameToSet]
          ),
          chainId: _networkId
        );
        getName();
      } catch (e2) {
        print("Echec final setName: $e2");
        isLoading = false;
        notifyListeners();
      }
    }
  }
}