graph TD
    
    Context:::oz --> IBox
    IBox:::interface --> BoxProxy
    IBox --> BoxBase
    BoxStorage:::abstract --> BoxProxy
    BoxStorage --> BoxBase
    BoxProxy:::abstract -->|Delegate| BoxBase:::deployed
    BoxProxy --> BoxWithTimeLock
  
    ERC721:::oz --> ERC721Typed
    ERC721Typed:::abstract --> ERC721TypedMintByLockingERC20
  
    BoxWithTimeLock:::abstract --> CryptoTreasure:::deployed

    ERC721TypedMintByLockingERC20:::abstract --> CryptoTreasure
    AccessControl:::oz --> CryptoTreasure

    classDef oz fill:white, stroke:grey;
    classDef abstract fill:#d6eaf8, stroke:#d6eaf8 ;
    classDef deployed fill:  #27ae60, stroke:green  ;
    classDef interface fill:  #ffffa2, stroke:yellow  ;