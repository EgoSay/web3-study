
import java.nio.charset.StandardCharsets;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.SecureRandom;
import java.security.Signature;
import javax.crypto.Cipher;
import java.util.Base64;

/*
 * @Author: Joe_Chan
 * @Date: 2024-07-02 18:18:19
 * @Description: 
 */

public class RSAExample {

    /**
     * 生成密钥对
     */
    public static KeyPair generateKeyPair() throws Exception {
        KeyPairGenerator keyGen = KeyPairGenerator.getInstance("RSA");
        SecureRandom random = SecureRandom.getInstanceStrong();
        // 2048 位的密钥长度
        keyGen.initialize(2048, random); 
        return keyGen.generateKeyPair();
    }

    /**
     * 使用公钥加密数据
     */
    public static String encrypt(String plainText, PublicKey publicKey) throws Exception {
        Cipher cipher = Cipher.getInstance("RSA");
        cipher.init(Cipher.ENCRYPT_MODE, publicKey);
        byte[] encryptedBytes = cipher.doFinal(plainText.getBytes("UTF-8"));
        return Base64.getEncoder().encodeToString(encryptedBytes);
    }

    /**
     * 使用私钥解密数据
     */
    public static String decrypt(String encryptedText, PrivateKey privateKey) throws Exception {
        byte[] encryptedBytes = Base64.getDecoder().decode(encryptedText);
        Cipher cipher = Cipher.getInstance("RSA");
        cipher.init(Cipher.DECRYPT_MODE, privateKey);
        byte[] decryptedBytes = cipher.doFinal(encryptedBytes);
        return new String(decryptedBytes, StandardCharsets.UTF_8);
    }

    /**
     * 使用私钥签名数据
     */
    public static String sign(String plainText, PrivateKey privateKey) throws Exception {
        Signature privateSignature = Signature.getInstance("SHA256withRSA");
        privateSignature.initSign(privateKey);
        privateSignature.update(plainText.getBytes(StandardCharsets.UTF_8));
        byte[] signature = privateSignature.sign();
        return Base64.getEncoder().encodeToString(signature);
    }

    /**
     * 使用公钥验证签名
     */
    public static boolean verify(String plainText, String signature, PublicKey publicKey) throws Exception {
        Signature publicSignature = Signature.getInstance("SHA256withRSA");
        publicSignature.initVerify(publicKey);
        publicSignature.update(plainText.getBytes(StandardCharsets.UTF_8));
        byte[] signatureBytes = Base64.getDecoder().decode(signature);
        return publicSignature.verify(signatureBytes);
    }

    public static void main(String[] args) {
        try {
            // 生成密钥对
            KeyPair keyPair = generateKeyPair();
            PublicKey publicKey = keyPair.getPublic();
            PrivateKey privateKey = keyPair.getPrivate();

            // 原始数据
            String originalHash = GenerateHash.generateHashWithLeadingZeros("Joe_chan", 4);
            System.out.println("满足条件的哈希值: " + originalHash);


            // 加密
            String encryptedText = encrypt(originalHash, publicKey);
            System.out.println("加密后的文本: " + encryptedText);

        
            // 解密
            String decryptedText = decrypt(encryptedText, privateKey);
            System.out.println("解密后的文本: " + decryptedText);

            // 签名
            String signature = sign(originalHash, privateKey);
            System.out.println("签名: " + signature);

            // 验证签名
            boolean isVerified = verify(originalHash, signature, publicKey);
            System.out.println("签名验证: " + isVerified);
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
