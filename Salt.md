# Configuration management with salt
## Prerequisites
Configure a *nfs-server* with following *exports*
```
/usr/lib/hpc	*(ro,root_squash,sync,no_subtree_check)
/usr/share/lmod/modulefiles	*(ro,root_squash,sync,no_subtree_check)
/usr/share/lmod/moduledeps	*(ro,root_squash,sync,no_subtree_check)
```

## Salt formulas
The salt formula */srv/salt/compute-node.sls* is used to configure the compute nodes. The formula has the contents
```
nfs-client:
    pkg.installed: []
neovim:
    pkg.installed: []
lua-lmod:
    pkg.installed: []
genders:
    pkg.installed: []

/usr/lib/hpc:
   mount.mounted:
      - device: leap15-clustduct:/usr/lib/hpc
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/usr/share/lmod/modulefiles:
   mount.mounted:
      - device: leap15-clustduct:/usr/share/lmod/modulefiles
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/usr/share/lmod/moduledeps:
   mount.mounted:
      - device: leap15-clustduct:/usr/share/lmod/moduledeps
      - fstype: nfs
      - mkmnt: True
      - opts:
         - defaults
      - require:
        - pkg: nfs-client

/etc/profile.d/lmod.sh:
    file.managed:
      - source: salt://shared_module/lmod.sh
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: lua-lmod

/etc/profile.d/lmod.csh:
    file.managed:
      - source: salt://shared_module/lmod.csh
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: lua-lmod

/etc/genders:
    file.managed:
      - contents_pillar: genders:database
      - mode: 644
      - user: root
      - group: root
      - require:
        - pkg: genders
```
and the definition for the node as *srv/salt/top.sls*
```
base:
  'compute-[0-2][0-9].cluster.suse':
    - compute-node

```
we also have to create the configuration files for *lua-lmod* with
```
mkdir /srv/salt/shared_module
cp /etc/profile.d/lmod* /srv/salt/shared_module
```
and create a pillar for distributing the genders database by creating the file `/srv/pillar/top.sls` with the content
```
base:
  '*':
    - genders
```
and the genders pillar `/srv/pillar/genders.sls`
```
genders:
    database: |
        {{ salt['cmd.run']('nodeattr --expand' ) | indent(8) }}
```
Now accept the key with
```
salt-key -A
```
and the node should install the rest.
