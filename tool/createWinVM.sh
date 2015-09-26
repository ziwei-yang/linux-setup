VM_NAME='winxp'
MEMORY=2048
NET_INTERFACE='em1'
DVD_PATH=$HOME/install.iso
DISK_DIR=$HOME/vmdisk
DISK_PATH=$DISK_DIR/winxp.vdi
DISK_SIZE=500000
RDE_PORT=3307

VBoxManage createvm -name $VM_NAME --register
VBoxManage modifyvm $VM_NAME --memory $MEMORY --acpi on --boot1 dvd --nic1 bridged --bridgeadapter1 $NET_INTERFACE
mkdir $DISK_DIR
VBoxManage createhd --filename $DISK_PATH --size 500000
VBoxManage storagectl "'$VM_NAME'" --name "IDE Controller" --add ide
VBoxManage storageattach "'$VM_NAME'" --storagectl "IDE Controller" --port 0 --device 0 --type hdd --medium $DISK_PATH
VBoxManage storageattach "'$VM_NAME'" --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium $DVD_PATH
VBoxManage modifyvm "'$VM_NAME'" --vrde on
VBoxManage modifyvm "'$VM_NAME'" --vrdeport $RDE_PORT

# Use below iso to install GuestAdditions
#Vboxmanage modifyvm 'winxp' --dvd /usr/share/virtualbox/VBoxGuestAdditions.iso

# echo "Starting $VM_NAME"
# VBoxHeadless -s "'$VM_NAME'"
