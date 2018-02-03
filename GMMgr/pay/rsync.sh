 #!/bin/sh 
 src=/home/chanyue/PHPPay
 tarList=(
	/home/zaiye/global/PHPPay
	/home/daomeng/global/PHPPay
	/home/anqu/global/PHPPay
	/home/feiyue/global/PHPPay
)

for tar in ${tarList[@]}  
do  
	echo ${tar}
	rsync -avl --exclude="config.php" --exclude="log.txt"  ${src}/ ${tar}/
	chmod 777 ${tar} -R
done  

