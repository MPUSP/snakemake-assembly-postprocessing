# Changelog

## [1.1.0](https://github.com/MPUSP/snakemake-assembly-postprocessing/compare/v1.0.0...v1.1.0) (2025-12-10)


### Features

* add prokka and bakta for annotation ([807df3a](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/807df3ab185f0e18663746d227831e54c55ddb2a))
* added bakta for annotation ([4a88b34](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/4a88b34ec0f871fea7c3d1ae12b22b5858a3ff63))
* added panaroo as a genome comparison tool, closes [#6](https://github.com/MPUSP/snakemake-assembly-postprocessing/issues/6) ([20e70b2](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/20e70b24062e621950812144af5600d21a0f7efe))
* added prokka for annotation ([1579c87](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/1579c874494d406216f77c15ccd3a300e89d4859))
* added quast, allow multiple annotation tools, allow local bakta db ([7d9f6cd](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/7d9f6cdbc1dc78b00f4d33344d245c70a375b7fe))


### Bug Fixes

* added missing dag. ([b1d0d34](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/b1d0d34f43934bcc91db506a95c1358db282c36b))
* added option to skip pangenome analysis ([0e829f6](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/0e829f6ca1746221565b90648ed712e5d23018e0))
* correct env names, use relative path for pgap fasta ([938ac49](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/938ac49de7be1258b910dc8167138fa17f8b39e3))
* merge commit ([d4cc6c5](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/d4cc6c55464b0d6515d67ca6885892e321eaceb4))
* pipe armfinder_update to log. ([a85d20b](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/a85d20bf22201ee00cffb5ae22047207fc07ad80))
* remove option to define output dir in config. ([0454259](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/04542596282eec63d5d54dfdce18b260b1590172))
* update armdfinder db when local db is used. update bakta version. ([db385f0](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/db385f0fce62cad5b188d865b8f84cab1e13b270))
* update readmes ([a4a147a](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/a4a147aa1fe1c18994d46bfd279e9b32afd7633e))
* updated schema ([7e9dfc0](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/7e9dfc0fb89daaa7ad6c961eb7dc083c56cbbc94))
* use absolute input paths for pgap helpers ([f4db893](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/f4db893567c9375d62bb2bd6a419ab86eed4b0b6))
* use correct input for quast reference, closes [#7](https://github.com/MPUSP/snakemake-assembly-postprocessing/issues/7) ([84c07a6](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/84c07a67fb10053b1a435afe2923652a75a50101))
* use results as standard output dir ([1b6695f](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/1b6695f502b40e88d5e43cdd38be1b06662a2d88))
* validate locus tag for bakta annotation; closes [#8](https://github.com/MPUSP/snakemake-assembly-postprocessing/issues/8) ([6048f72](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/6048f72a5c0ad16ca09f365aeb37bc2175c398f4))

## 1.0.0 (2025-12-03)


### Features

* add pgap annotation; closes [#2](https://github.com/MPUSP/snakemake-assembly-postprocessing/issues/2) ([2f5d6c8](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/2f5d6c849f6f3f7d29229967c7d2666c8aac228d))


### Bug Fixes

* snakefmt issue ([6eb303b](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/6eb303b3d1ded717f7f3ef1775dbcf181405631d))
* yaml formatting issue ([5125d55](https://github.com/MPUSP/snakemake-assembly-postprocessing/commit/5125d559a9480f5d300909ee0c0605a805500ba4))
