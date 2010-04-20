#!/bin/sh

working_dir=`pwd`/out
vm_bin_dir=$working_dir/squeakvm

pharo_version="PharoCore-1.0-10517"
squeak_rev=2188
configuration_of_vmmaker='1.3'
internal_plugins="UUIDPlugin FT2Plugin"


pharo_dir=$working_dir/$pharo_version
pharo_image=$pharo_dir/$pharo_version.image
pharo_archive=$pharo_dir.zip
download_url="https://gforge.inria.fr/frs/download.php/26775/$pharo_archive"

squeak_dir=$working_dir/platforms
squeak_svn="http://squeakvm.org/svn/squeak/trunk/platforms/"


if [ ! -d $working_dir ]; then
    mkdir $working_dir
fi
cd $working_dir


echo "Checkout Squeak VM sources"
if [ ! -d $squeak_dir ]; then
    svn co $squeak_svn -r $squeak_rev
fi


echo "Download PharoCore 1.0"
if [ ! -e $pharo_archive ]; then
    wget $download_url
fi


echo "Unzip PharoCore archive"
if [ ! -d $pharo_dir ]; then
    unzip $pharo_archive
fi


echo "Load VMMaker"
loadst="`pwd`/load.st"
if [ ! -e $loadst ]; then
    echo "Author fullName: 'EasySqueakVM'.
          Gofer new 
            squeaksource: 'MetacelloRepository';
            package: 'ConfigurationOfVMMaker';
            load.
          ((Smalltalk at: #ConfigurationOfVMMaker) 
                    project version: '$configuration_of_vmmaker') load.
          SmalltalkImage current snapshot: true andQuit: true." > $loadst
    squeak -headless $pharo_image $loadst
fi


echo "Generate source"
generatest="`pwd`/generate.st"
if [ ! -e $generatest ]; then
    echo "(VMMaker forPlatform: 'unix')
               platformRootDirectoryName: '$squeak_dir';
               initializeAllExternalBut: #($internal_plugins);
               generateEntire.
               SmalltalkImage current snapshot: true andQuit: true." > $generatest
fi
squeak -headless $pharo_image $generatest

echo "Building VM"
if [ -d build ]; then
    rm -rf build;
fi
mkdir build && cd build
$squeak_dir/unix/cmake/configure --src=$pharo_dir/src32 --prefix=$vm_bin_dir
make && make install

echo "Finished !"