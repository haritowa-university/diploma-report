import Foundation
import SwCrypt

enum KeyGenerationError: Error 
{
    case cantDeriveKeyFromPin(Error)

    case cantCreateAESKey
    case cantCreateRSAKeyPair(Error)
    case cantConvertPemToRSAKey(Error)
}

enum CryptError: Error 
{
    enum AESError: Error 
    {
        case cantEncrypt(Error)
        case cantDecrypt(Error)
    }

    enum RSAError {
        case cantEncrypt(Error)
        case cantDencrypt(Error)
    }

    case identityAlreadyExist(data: [UserCryptIdentity.IdentityKey])

    case wrongPinLength
    case wrongPin

    case cantStoreIdentity
    case cantReadIdentity

    // Case for any other error
    case unknown(error: Error)
}