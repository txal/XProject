# /sbin/bash

echo 更新======
pushd ../../Data
svn update 
popd

pushd ../../Server
svn update
popd

echo 协议======
pushd ../../Data/Protobuf
php ServerPBList.php
popd


