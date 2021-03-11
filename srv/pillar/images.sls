images:
  leap15SP3:
    name: "Boot openSUSE Leap 15 SP3"
    kernel: /dolly15.1/Leap-HPC-15.1-JeOS.x86_64-1.15.0.kernel
    initrd: /dolly15.1/pxeboot.Leap-HPC-15.1-JeOS.x86_64-1.15.0.initrd.xz
    mandatory: True
    args:
      - 'append=rd.kiwi.install.pxe'
      - 'rd.debug=1'
      - 'rd.kiwi.debug=1'
      - 'rd.kiwi.install.image=tftp://192.168.100.254/dolly15.1/Leap-HPC-15.1-JeOS.x86_64-1.15.0.xz'
