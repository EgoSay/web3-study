import java.security.MessageDigest;
import java.util.Random;

/**
 * @author Joe_Chan
 * @version 1.0
 * @date 2024/7/2 17:07
 * @since JDK1.8
 */
public class GenerateHash {
    public static void main(String[] args) {
        // 初始化值
        String initialValue = "Joe_chan";
        System.out.println("满足条件的哈希值: " + generateHashWithLeadingZeros(initialValue, 4));
        System.out.println("满足条件的哈希值: " + generateHashWithLeadingZeros(initialValue, 5));
    }

    public static String generateHashWithLeadingZeros(String initialValue, int leadingZeroCount) {
        Random random = new Random();
        String hash = "";
        String targetPrefix = new String(new char[leadingZeroCount]).replace('\0', '0');
        long startTime = System.currentTimeMillis();
        while (true) {
            int randomValue = random.nextInt();
            String combinedValue = initialValue + randomValue;
            hash = sha256(combinedValue);

            if (hash.startsWith(targetPrefix)) {
                System.out.println("花费时间: " + (System.currentTimeMillis() - startTime) + "ms");
                System.out.println("对应的组合字符串: " + combinedValue);
                break;
            }
        }

        return hash;
    }

    private static String sha256(String base) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(base.getBytes("UTF-8"));
            StringBuilder hexString = new StringBuilder();

            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) {
                    hexString.append('0');
                }
                hexString.append(hex);
            }

            return hexString.toString();
        } catch (Exception ex) {
            throw new RuntimeException(ex);
        }
    }
}

