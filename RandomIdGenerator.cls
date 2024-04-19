/**
 * Created by arthurvandevelde on 10/04/2024.
 */

public with sharing class RandomIdGenerator {
    public static String generateRandomString(Integer length) {
        String allowedChars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        String randomString = '';

        while (randomString.length() < length) {
            Integer randomInt = Math.mod(Math.abs(Crypto.getRandomInteger()), allowedChars.length());
            randomString += allowedChars.substring(randomInt, randomInt + 1);
        }

        return randomString;
    }
}