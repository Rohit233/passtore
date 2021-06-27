package com.coder.passstore;

import android.Manifest;
import android.annotation.SuppressLint;
import android.annotation.TargetApi;
import android.app.KeyguardManager;
import android.content.pm.PackageManager;
import android.hardware.fingerprint.FingerprintManager;
import android.os.Build;
import android.os.Bundle;
import android.os.PersistableBundle;
import android.security.keystore.KeyGenParameterSpec;
import android.security.keystore.KeyPermanentlyInvalidatedException;
import android.security.keystore.KeyProperties;
import android.widget.Toast;


import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.biometric.BiometricManager;
import androidx.biometric.BiometricPrompt;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.FragmentActivity;

import java.io.IOException;
import java.io.UnsupportedEncodingException;
import java.security.InvalidAlgorithmParameterException;
import java.security.InvalidKeyException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.util.Base64;
import java.util.concurrent.Executor;

import javax.crypto.BadPaddingException;
import javax.crypto.Cipher;
import javax.crypto.IllegalBlockSizeException;
import javax.crypto.KeyGenerator;
import javax.crypto.NoSuchPaddingException;
import javax.crypto.SecretKey;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;

@TargetApi(Build.VERSION_CODES.M)
public class MainActivity extends FlutterActivity{
    private static final String CHANNEL="NativeCode/EncyAndDecry";
    private static final String CHANNEL1="NativeCode/auth";
    private static final String encryptionKey           = "1ZGPLFCXTQMEKNJ2";
    private static final String characterEncoding       = "UTF-8";
    private static final String cipherTransformation    = "AES/CBC/PKCS5PADDING";
    private static final String aesEncryptionAlgorithem = "AES";
    FingerprintManager fingerprintManager;
    private KeyguardManager keyguardManager;
    private KeyStore keyStore;
    private Cipher cipher;
    private String KEY_NAME="AKEYS";

    @Override
    public void configureFlutterEngine(FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        GeneratedPluginRegistrant.registerWith(flutterEngine);
        new MethodChannel(getFlutterEngine().getDartExecutor(),CHANNEL).setMethodCallHandler(
                new MethodChannel.MethodCallHandler() {
                    @Override
                    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
                        if(methodCall.method.equals("Encrypt")){
                            String EncryptText=EncryptString(methodCall.argument("text"));
                            result.success(EncryptText);
                        }
                        else if(methodCall.method.equals("Decrypt")){
                            String decryptText=decrypt(methodCall.argument("encryptedText"));
                            result.success(decryptText);
                        }
                    }
                }
        );

        new MethodChannel(getFlutterEngine().getDartExecutor(),CHANNEL1).setMethodCallHandler(new MethodChannel.MethodCallHandler() {
            @RequiresApi(api = Build.VERSION_CODES.M)
            @Override
            public void onMethodCall(MethodCall methodCall, MethodChannel.Result result){
                if(methodCall.method.equals("finger")){
                 if(Build.VERSION.SDK_INT>=Build.VERSION_CODES.M){
                     fingerprintManager=(FingerprintManager)getSystemService(FINGERPRINT_SERVICE);
                     keyguardManager=(KeyguardManager)getSystemService(KEYGUARD_SERVICE);
                     if(!fingerprintManager.isHardwareDetected()){
                         Toast.makeText(getApplicationContext(),"No fingur print scanner",Toast.LENGTH_LONG).show();
                     }
                     else if(getApplicationContext().checkSelfPermission( Manifest.permission.USE_FINGERPRINT)!= PackageManager.PERMISSION_GRANTED){

                     }
                     else if(!keyguardManager.isKeyguardSecure()){
                       Toast.makeText(getApplicationContext(),"Add Look to phone",Toast.LENGTH_LONG).show();

                     }
                     else if(fingerprintManager.hasEnrolledFingerprints()){
                         generateKey();
                         if(cipherInit()) {
                             FingerprintManager.CryptoObject cryptoObject=new FingerprintManager.CryptoObject(cipher);
                             FingerPrintHandler fingerPrintHandler = new FingerPrintHandler(getApplicationContext(),result);
                             fingerPrintHandler.startAuth(fingerprintManager, cryptoObject);

                         }
                         }
                 }
                }
            }
        });
    }
    @TargetApi(Build.VERSION_CODES.M)
    private void generateKey(){
        try {
          keyStore=KeyStore.getInstance("AndroidKeyStore");
            KeyGenerator keyGenerator=KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES,"AndroidKeyStore");
            keyStore.load(null);
            keyGenerator.init(
                    new KeyGenParameterSpec.Builder(KEY_NAME,
                            KeyProperties.PURPOSE_ENCRYPT |
                                    KeyProperties.PURPOSE_DECRYPT)
                    .setBlockModes(KeyProperties.BLOCK_MODE_CBC)
                    .setUserAuthenticationRequired(true)
                    .setEncryptionPaddings(
                            KeyProperties.ENCRYPTION_PADDING_PKCS7
                     ).build()
                    );
            keyGenerator.generateKey();
        } catch (KeyStoreException e) {
            e.printStackTrace();
        } catch (NoSuchAlgorithmException e) {
            e.printStackTrace();
        } catch (NoSuchProviderException e) {
            e.printStackTrace();
        } catch (CertificateException e) {
            e.printStackTrace();
        } catch (IOException e) {
            e.printStackTrace();
        } catch (InvalidAlgorithmParameterException e) {
            e.printStackTrace();
        }
    }
    @TargetApi(Build.VERSION_CODES.M)
    public boolean cipherInit() {
        try {
            cipher = Cipher.getInstance(KeyProperties.KEY_ALGORITHM_AES + "/" + KeyProperties.BLOCK_MODE_CBC + "/" + KeyProperties.ENCRYPTION_PADDING_PKCS7);
        } catch (NoSuchAlgorithmException | NoSuchPaddingException e) {
            throw new RuntimeException("Failed to get Cipher", e);
        }


        try {

            keyStore.load(null);

            SecretKey key = (SecretKey) keyStore.getKey(KEY_NAME,
                    null);

            cipher.init(Cipher.ENCRYPT_MODE, key);

            return true;

        } catch (@SuppressLint("NewApi") KeyPermanentlyInvalidatedException e) {
            return false;
        } catch (KeyStoreException | CertificateException | UnrecoverableKeyException | IOException | NoSuchAlgorithmException | InvalidKeyException e) {
            throw new RuntimeException("Failed to init Cipher", e);
        }

    }
   public String  EncryptString(String Plaintext){
        String encryptedText="";
       try {
           Cipher cipher=Cipher.getInstance(cipherTransformation);
           byte[] key=encryptionKey.getBytes(characterEncoding);
           SecretKeySpec secretKeySpec=new SecretKeySpec(key,aesEncryptionAlgorithem);
           IvParameterSpec ivParameterSpec=new IvParameterSpec(key);
           cipher.init(Cipher.ENCRYPT_MODE,secretKeySpec,ivParameterSpec);
           byte[]cipherText=cipher.doFinal(Plaintext.getBytes("UTF8"));
           Base64.Encoder encoder=Base64.getEncoder();
           encryptedText=encoder.encodeToString(cipherText);
       } catch (NoSuchAlgorithmException e) {
           e.printStackTrace();
       } catch (NoSuchPaddingException e) {
           e.printStackTrace();
       } catch (UnsupportedEncodingException e) {
           e.printStackTrace();
       } catch (InvalidAlgorithmParameterException e) {
           e.printStackTrace();
       } catch (InvalidKeyException e) {
           e.printStackTrace();
       } catch (BadPaddingException e) {
           e.printStackTrace();
       } catch (IllegalBlockSizeException e) {
           e.printStackTrace();
       }
  return  encryptedText;
   }
    public static String decrypt(String encryptedText) {
        String decryptedText = "";
        try {
            Cipher cipher = Cipher.getInstance(cipherTransformation);
            byte[] key = encryptionKey.getBytes(characterEncoding);
            SecretKeySpec secretKey = new SecretKeySpec(key, aesEncryptionAlgorithem);
            IvParameterSpec ivparameterspec = new IvParameterSpec(key);
            cipher.init(Cipher.DECRYPT_MODE, secretKey, ivparameterspec);
            Base64.Decoder decoder = Base64.getDecoder();
            byte[] cipherText = decoder.decode(encryptedText.getBytes("UTF8"));
            decryptedText = new String(cipher.doFinal(cipherText), "UTF-8");

        } catch (Exception E) {
            System.err.println("decrypt Exception : "+E.getMessage());
        }
        return decryptedText;
    }

}
