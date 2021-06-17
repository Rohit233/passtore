package com.coder.passstore;

import android.annotation.TargetApi;
import android.content.Context;
import android.hardware.fingerprint.FingerprintManager;
import android.os.Build;
import android.os.CancellationSignal;
import android.widget.Toast;

import io.flutter.plugin.common.MethodChannel;

@TargetApi(Build.VERSION_CODES.M)
public class FingerPrintHandler extends FingerprintManager.AuthenticationCallback {
private Context context;
private MethodChannel.Result result;
   public FingerPrintHandler(Context context,MethodChannel.Result result){
       this.context=context;
       this.result=result;
   }
   public void startAuth(FingerprintManager fingerprintManager,FingerprintManager.CryptoObject cryptoObject){
       CancellationSignal cancellationSignal=new CancellationSignal();
       fingerprintManager.authenticate(cryptoObject,cancellationSignal,0,this,null);

   }

    @Override
    public void onAuthenticationError(int errorCode, CharSequence errString) {
        super.onAuthenticationError(errorCode, errString);
        Toast.makeText(context,"Error",Toast.LENGTH_LONG).show();
        result.success("Error");
    }

    @Override
    public void onAuthenticationFailed() {
        super.onAuthenticationFailed();
        Toast.makeText(context,"Failed",Toast.LENGTH_LONG).show();
        result.success("Failed");
    }

    @Override
    public void onAuthenticationSucceeded(FingerprintManager.AuthenticationResult result) {
        super.onAuthenticationSucceeded(result);
        Toast.makeText(context,"succeeded",Toast.LENGTH_LONG).show();
       this.result.success("succeeded");
   }
}
