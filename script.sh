APP=$1
SPLIT_CONFIG=""
FORMAT=${APP##*.}
KEY=my-release-key.keystore
UNITY_CONFIG=boot.config
#UNITY_LIB=unity-2018.4.2f1-d6fb3630ea75/libunity.so
IL2CPP_LIB=il2cpp/libil2cpp.so

set -x

sign_apk()
{
	APK=$1
	mkdir -p .tmp
	unzip $APK -d .tmp >/dev/null
	cd .tmp
	UNSIGNED=${APK%.*}_unsigned.apk
	zip -0r ../$UNSIGNED *  >/dev/null
	cd ..
	ALIGNED=${UNSIGNED%.*}_aligned.apk
	cp  $UNSIGNED $ALIGNED
	#zipalign -p 4 $UNSIGNED $ALIGNED
	rm $UNSIGNED
	./apksigner sign --ks my-release-key.keystore  --ks-key-alias alias_name $ALIGNED
	./apksigner verify $ALIGNED
	mv $ALIGNED $APK
	rm -r .tmp
}

add_unity_config()
{
	APK=$1
	CONFIG=$2
	mkdir -p tmp/assets/bin/Data
	cp $CONFIG tmp/assets/bin/Data
	cd tmp
	zip -r assets/bin/Data/$CONFIG $APK  >/dev/null
	cd ..
}

add_lib()
{
	APK=$1
	LIB=$2
	mkdir -p tmp/lib/armeabi-v7a
	cp $LIB tmp/lib/armeabi-v7a
	cd tmp
	zip -r lib/armeabi-v7a/$LIB $APK  >/dev/null
	cd ..
}

if [ ! -f "$KEY" ] ; then
	keytool -genkey -v -keystore my-release-key.keystore -alias alias_name -keyalg RSA -keysize 2048 -validity 10000
fi

mkdir -p tmp
unzip $APP -d tmp
if [ "$FORMAT" == "xapk" ] ; then
	for line in $(cat tmp/manifest.json  | tr "," "\n")
	do
		key=$(echo $line | cut -d ":" -f1 | sed "s,\",,g")
		if [ "$key" == "package_name" ] ; then
			value=$(echo $line | cut -d ":" -f2 | sed "s,\",,g")
			APP="$value.apk"
		fi
		if [ "$key" == "split_configs" ] ; then
			value=$(echo $line | cut -d ":" -f2 | sed "s,\",,g" | sed "s,\[,,g" | sed "s,\],,g")
			SPLIT_CONFIG="$value.apk"
		fi
	done
	echo "Found apk tmp/$APP"
	echo "Found apk tmp/$SPLIT_CONFIG"

	if [ "$UNITY_LIB" != "" ] ; then
		echo "Adding unity library"
		add_lib $SPLIT_CONFIG $UNITY_LIB
	fi

	if [ "$IL2CPP_LIB" != "" ] ; then
		echo "Adding il2cpp library"
		add_lib $SPLIT_CONFIG $IL2CPP_LIB
	fi

	echo "Signing tmp/$SPLIT_CONFIG"
	sign_apk "tmp/$SPLIT_CONFIG"

	if [ "$UNITY_CONFIG" != "" ] ; then
		echo "Adding unity config"
		add_unity_config "$APP" $UNITY_CONFIG
	fi

	echo "Signing tmp/$APP"
	sign_apk "tmp/$APP"
	cd tmp
	rm -r assets
	zip -9r ../${APP%.*}_unsigned.xapk *
	rm -r tmp
fi

if [ "$FORMAT" == "apk" ] ; then
	mkdir -p tmp
	cp $APP tmp

	echo "Adding unity config"
	add_unity_config $APP boot.config

	if [ "$UNITY_LIB" != "" ] ; then
		echo "Adding unity library"
		add_lib $APP $UNITY_LIB
	fi

	if [ "$IL2CPP_LIB" != "" ] ; then
		echo "Adding il2cpp library"
		add_lib $APP $IL2CPP_LIB
	fi

	echo "Signing tmp/$APP"
	sign_apk "tmp/$APP"
	mv tmp/$APP ${APP%.*}_signed.apk
fi
