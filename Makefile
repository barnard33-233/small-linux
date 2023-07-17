#!/bin/bash
INIT=initramfs.cpio.gz
ROOT=rootfs.img
ROOTFS=./rootfs
BZIMAGE=./linux/arch/x86_64/boot/bzImage
BUSYBOX=./busybox/busybox/busybox-1.36.1/_install/

default: $(INIT) $(ROOT)

all: $(ROOTFS) $(INIT) $(ROOT) run

realall: clean all

.PHONY:run clean

$(ROOTFS):
	-@echo @rootfs
	cp -r $(BUSYBOX)/* $(ROOTFS)
	mkdir $(ROOTFS)/proc $(ROOTFS)/sys $(ROOTFS)/dev

$(INIT): $(ROOTFS)/*
	find ./rootfs/ -print0 | cpio --null -ov --format=newc | gzip -9 > $(INIT)

$(ROOT): mnt $(ROOTFS)/*
	dd if=/dev/zero of=$(ROOT) bs=1M count=64
	mkfs.ext4 $(ROOT)
	sudo mount -t ext4 -o loop $(ROOT) ./mnt
	sudo cp -r $(ROOTFS)/* ./mnt
	sudo umount ./mnt
	
mnt:
	mkdir ./mnt

run:
	-@echo @run
	qemu-system-x86_64 \
	-kernel $(BZIMAGE) \
	-initrd ./$(INIT) \
	-hda ./$(ROOT) \
	-append "root=/dev/sda console=ttyS0 nokalsr" \
	-serial stdio

clean:
	-@rm ./$(INIT)
	-@rm ./$(ROOT)
