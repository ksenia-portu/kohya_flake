{
  inputs = {
    nixpkgsUnstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixpkgsStable.url = "github:NixOS/nixpkgs/nixos-23.11";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    };

  outputs = inputs @ { flake-parts, ... }:
   flake-parts.lib.mkFlake { inherit inputs; } {
    systems = import inputs.systems;

    perSystem = { pkgs, system, pkgsN, ... }: let
      nixpkgsSetup = {
	_module.args.pkgs = import inputs.nixpkgsStable {
          inherit system;
	   config = {
              allowUnfree = true;
              cudaSupport = true;
              #allowBroken = true;
	    };
	};
        _module.args.pkgsN = import inputs.nixpkgsStable {
          inherit system;
          overlays = [ (self: super: {
            python310 = super.python310.override { x11Support = true; };
          })];
          config = {
            allowUnfree = true;
            cudaSupport = true;
            #allowBroken = true;
          };
        };

      };
                              
      python = pkgs.python310;
      pythonEnvHook = python.withPackages (pkgs: with pkgs; [
        python
        pip
        virtualenv
        venvShellHook
        ]);

      pythonEnvN = pkgsN.python310.withPackages (p: with p; [
        #insightface
        #torch
        tkinter
        #(tkinter.override{x11Support = true;})
        ]);

      pythonEnv = python.withPackages (pkgs: with pkgs; [
        #clip-anytorch
        onnx
        onnxruntime
        torchdiffeq
        xformers
        kornia
        deepdiff
        diskcache
        #diffusers
        einops
        flatbuffers
        ffmpeg-python
        gitpython
        huggingface-hub
        imageio
        imageio-ffmpeg
        matplotlib
        moviepy
        natsort
        numba
        numexpr
        omegaconf
        #opencv4
        openai
        packaging
        pandas
        piexif
        pillow                                  
        #pip
        #plyfile
        protobuf
        psutil
        py-cpuinfo
        pycocotools
        pygments
        pyopenssl
        py3nvml
        pynvml
        pyyaml
        pyqt5
        #pytorch-bin
        regex
        rich
        safetensors
        scikit-build
        scikit-image
        scikit-learn
        scipy
        seaborn
        simpleeval
        #torchWithCuda
        #torchvision
        #tkinter #{ x11Support = true; }
        torch
        torchsde
        torchvision
        tqdm
        trimesh
        transformers
        watchdog
        wrapt 
        yapf 
        ]);        
      essentials = with pkgs; [ 
        cudaPackages.cudatoolkit
        dlib
        ffmpeg
        gcc
        git
        glib
        glibc
        gmp
        libsForQt5.full
        libcxx
        libffi
        libffi.dev
        libGL
        libGLU
        openssl
        stdenv.cc
        stdenv.cc.cc
        zlib
        zlib.dev
        zsh
        #python311Packages.pyqt5
      ];
      cclib = "${pkgs.stdenv.cc.cc.lib}/lib";
      opengllib = "/run/opengl-driver/lib";
      libpath = pkgs.lib.makeLibraryPath essentials;
	in {
      devShells.default = pkgsN.mkShell {
        name = "default dev shell";                                      
        venvDir = "./.venv";
        buildInputs = with pkgsN; [
          pythonEnv
          pythonEnvN
          pythonEnvHook
          essentials
        ];
      shellHook = ''
        echo "Entering dev shell"
        export LD_LIBRARY_PATH=${cclib}:${opengllib}:${libpath}
        export CUDA_PATH=${pkgs.cudatoolkit}
      '';
      # Run this command, only after creating the virtual environment
      postVenvCreation = ''
        unset SOURCE_DATE_EPOCH
        pip install -r requirements.txt
      '';

      # Now we can execute any commands within the virtual environment.
      # This is optional and can be left out to run pip manually.
      postShellHook = ''
        # allow pip to install wheels
        unset SOURCE_DATE_EPOCH
      '';
      };        
     }// nixpkgsSetup;
   };

  nixConfig = {
    extra-substituters = [ 
            "https://numtide.cachix.org"
            # nixified-ai
            #"https://ai.cachix.org"
          ];
	  extra-trusted-public-keys = [ 
            "numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE=" 
	    # nixified-ai
            #"ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="            
          ];
	};
}   
