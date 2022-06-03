 ;;; hlsl-mode.el --- major mode for Open HLSL shader files

;; Copyright (C) 2022 Free Software Foundation, Inc.
;;
;; Author: Xichen Zhou
;; Keywords: languages HLSL shader
;; Version: 1.0

;; This file is part of GNU Emacs.

;; GNU Emacs is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Major mode for editing HLSL grammar files, usually files ending
;; with '(.fxh|.hlsl)'.  Is is based on c-mode plus some features
;; and pre-specified fontifications.
;;; Code:

(eval-when-compile			; required and optional libraries
  (require 'cc-mode)
  (require 'find-file))

(require 'align)

(defgroup hlsl nil
  "DirectX Shading Language Major Mode"
  :group 'languages)

(defconst hlsl-version "6.0"
  "HLSL major mode version number.")

(defvar hlsl-mode-hook nil)

(defvar hlsl-mode-menu nil "Menu for GLSL mode")

(defvar hlsl-mode-map
  (let ((hlsl-mode-map (make-sparse-keymap)))
    (define-key hlsl-mode-map [S-iso-lefttab] 'ff-find-other-file)
    hlsl-mode-map)
  "Keymap for HLSL major mode.")

;; keywords
(eval-and-compile
  (defvar hlsl-type-list
    '("half" "float" "double" "int" "uint""byte" "bool"     ;; scalar
      "min16float" "min10float"  "min16int" "min16uint" "min12int" "min12uint"
      ;; vector
      "half1" "half2" "half3" "half4" "float1" "float2" "float3" "float4"
      "double1" "double2" "double3" "double4"
      "int1" "int2" "int3" "int4" "uint1" "uint2" "uint3" "uint4"
      "bool1" "bool2" "bool3" "bool4" "byte1" "byte2" "byte3" "byte4"
      ;; half mat
      "half1x1" "half1x2" "half1x3" "half1x4"
      "half2x1" "half2x2" "half2x3" "half2x4"
      "half3x1" "half3x2" "half3x3" "half3x4"
      "half4x1" "half4x2" "half4x3" "half4x4"
      ;; float mat
      "float1x1" "float1x2" "float1x3" "float1x4"
      "float2x1" "float2x2" "float2x3" "float2x4"
      "float3x1" "float3x2" "float3x3" "float3x4"
      "float4x1" "float4x2" "float4x3" "float4x4"
      ;; double mat
      "double1x1" "double1x2" "double1x3" "double1x4"
      "double2x1" "double2x2" "double2x3" "double2x4"
      "double3x1" "double3x2" "double3x3" "double3x4"
      "double4x1" "double4x2" "double4x3" "double4x4"
      ;; int mat
      "int1x1" "int1x2" "int1x3" "int1x4"
      "int2x1" "int2x2" "int2x3" "int2x4"
      "int3x1" "int3x2" "int3x3" "int3x4"
      "int4x1" "int4x2" "int4x3" "int4x4"
      ;; uint mat
      "uint1x1" "uint1x2" "uint1x3" "uint1x4"
      "uint2x1" "uint2x2" "uint2x3" "uint2x4"
      "uint3x1" "uint3x2" "uint3x3" "uint3x4"
      "uint4x1" "uint4x2" "uint4x3" "uint4x4"
      ;; byte mat
      "byte1x1" "byte1x2" "byte1x3" "byte1x4"
      "byte2x1" "byte2x2" "byte2x3" "byte2x4"
      "byte3x1" "byte3x2" "byte3x3" "byte3x4"
      "byte4x1" "byte4x2" "byte4x3" "byte4x4"
      ;; bool mat
      "bool1x1" "bool1x2" "bool1x3" "bool1x4"
      "bool2x1" "bool2x2" "bool2x3" "bool2x4"
      "bool3x1" "bool3x2" "bool3x3" "bool3x4"
      "bool4x1" "bool4x2" "bool4x3" "bool4x4"
      ;;sampler
      "sampler" "sampler1D" "sampler2D" "sampler3D" "samplerCUBE"
      "SamplerState"
      ;;texture
      "Texture1D" "Texture2D" "Texture3D" "TextureCube" "Texture2DMS"
      "Texture1DArray" "Texture2DArray" "Texture2DMSArray" "TextureCubeArray"
      ;;RWTexture
      "RWTexture1D" "RWTexture2D" "RWTexture3D" "RWTexture1DArray"
      "RWTexture3DArray"
      ;;buffer
      "Buffer" "ByteAddressBuffer" "StructuredBuffer" "TextureBuffer"
      "tbuffer" "cbuffer" "AppendStructuredBuffer" "ConsumeStructuredBuffer"
      "ConstantBuffer"
      "RWBuffer" "RWByteAddressBuffer" "RWStructuredBuffer"
      ;;ray tracing
      "RaytracingAccelerationStructure"
      ;;user defined typedef vector<bool, 1>
      "vector" "matrix"
      ))

  (defvar hlsl-qualifier-list
    '("const" "precise" "nointerpolation"  "shared" "groupshared"
      "column_major" "row_major" "uniform"
      ))

  (defvar hlsl-keyword-list
    '("break" "continue" "do" "for" "while" "if" "else" "subroutine" "extern"
      "discard" "return" "precision" "struct" "class" "switch" "default" "case"
      "namespace" "void" "volatile" "static" "extern" "inout" "in" "out"
      "inline"
      ))

  (defvar hlsl-reserved-list
    '("typedef" "asm" "unsigned" "enum" "export"))

  (defvar hlsl-builtin-list
    '("abort" "abs" "acos" "all" "AllMemoryBarrier"
      "AllMemoryBarrierWithGroupSync" "any" "asdouble" "asfloat" "asin" "asint"
      "asuint" "atan" "atan2" "ceil" "CheckAccessFullyMapped" "clamp" "clip"
      "cos" "cosh" "countbits" "cross" "D3DCOLORtoUBYTE4" "ddx" "ddx_coarse"
      "ddx_fine" "ddy" "ddy_coarse" "ddy_fine" "degrees" "determinant"
      "DeviceMemoryBarrier" "DeviceMemoryBarrierWithGroupSync" "distance"
      "dot" "dst" "errorf" "EvaluateAttributeAtCentroid"
      "EvaluateAttributeAtSample" "EvaluateAttributeSnapped" "exp" "exp2"
      "f16tof32" "f32tof16" "faceforward" "firstbithigh" "firstbitlow" "floor"
      "fma" "fmod" "frac" "frexp" "fwidth" "GetRenderTargetSampleCount"
      "GetRenderTargetSamplePosition" "GroupMemoryBarrier"
      "GroupMemoryBarrierWithGroupSync" "InterlockedAdd" "InterlockedAnd"
      "InterlockedCompareExchange" "InterlockedCompareStore"
      "InterlockedExchange" "InterlockedMax" "InterlockedMin" "InterlockedOr"
      "InterlockedXor" "isfinite" "isinf" "isnan" "ldexp" "length" "lerp"
      "lit" "log" "log10" "log2" "mad" "max" "min" "modf" "msad4" "mul" "noise"
      "normalize" "pow" "printf" "Process2DQuadTessFactorsAvg"
      "Process2DQuadTessFactorsMax" "Process2DQuadTessFactorsMin"
      "ProcessIsolineTessFactors" "ProcessQuadTessFactorsAvg"
      "ProcessQuadTessFactorsMax" "ProcessQuadTessFactorsMin"
      "ProcessTriTessFactorsAvg" "ProcessTriTessFactorsMax"
      "ProcessTriTessFactorsMin" "radians" "rcp" "reflect" "refract"
      "reversebits" "round" "rsqrt" "saturate" "sign" "sin" "sincos" "sinh"
      "smoothstep" "sqrt" "step" "tan" "tanh" "tex1D" "tex1Dbias" "tex1Dgrad"
      "tex1Dlod" "tex1Dproj" "tex2D" "tex2Dbias" "tex2Dgrad" "tex2Dlod"
      "tex2Dproj" "tex3D" "tex3Dbias" "tex3Dgrad" "tex3Dlod" "tex3Dproj"
      "texCUBE" "texCUBEbias" "texCUBEgrad" "texCUBElod" "texCUBEproj"
      "transpose" "trunc"
      ))

  (defvar hlsl-const-list
    '("NULL" "true" "false"))

  (defvar hlsl-semantics-list
    '(;;vertex shader
      "BINORMAL[0-9]?" "BLENDINDICES[0-9]?" "BLENDWEIGHT[0-9]?" "COLOR[0-9]?"
      "NORMAL[0-9]?" "POSITION[0-9]?" "POSITIONT" "PSIZE[0-9]?" "TANGENT[0-9]?"
      "TEXCOORD[0-9]?" "TESSFACTOR[0-9]?" "FOG"
      ;;pixel shader
      "VFACE" "VPOS" "DEPTH[0-9]?"))

  (defvar hlsl-preprocessor-directive-list
    '("define" "undef" "if" "ifdef" "ifndef" "else" "elif" "endif"
      "error" "pragma" "extension" "version" "line" "include"))

  (defvar hlsl-preprocessor-builtin-list
    '("__LINE__" "__FILE__" "__VERSION__"))
  )

(eval-and-compile
  (defun hlsl-pp (exprs)
    "concatenate the regular expressions, it does not optimize"
    (format "\\<\\(%s\\)\\>"
	    (mapconcat (lambda (x) (format "%s" x)) exprs "\\|"))))

(eval-and-compile
  (defun hlsl-ppre (re)
    (format "\\<\\(%s\\)\\>" (regexp-opt re))))

(regexp-opt hlsl-keyword-list)
(defconst hlsl-font-lock-keywords-1
  `(
    ;; macros
    (,(hlsl-ppre hlsl-preprocessor-builtin-list) . font-lock-constant-face)
    (,(format  "^[ \t]*#[ \t]*\\<\\(%s\\)\\>"
	       (regexp-opt hlsl-preprocessor-directive-list))
     . font-lock-preprocessor-face)
    ;;#if defined macro
    ("^#[ \t]*\\(elif\\|if\\)\\>"
     ("\\<\\(defined\\)\\>[ \t]*(?\\(\\sw+\\)?" nil nil
      (1 font-lock-preprocessor-face) (2 font-lock-variable-name-face nil t)))
    ;; words
    (,(hlsl-ppre hlsl-type-list)      . 'font-lock-type-face)
    (,(hlsl-ppre hlsl-qualifier-list) . 'font-lock-keyword-face)
    (,(hlsl-ppre hlsl-keyword-list)   . 'font-lock-keyword-face)
    ;;function name
    ("\\<\\(\\sw+\\) ?(" (1 'font-lock-function-name-face))
    ;;others
    ("SV_[A-Za-z_]+"                  . 'font-lock-variable-name-face)
    (,(hlsl-pp hlsl-semantics-list)   . 'font-lock-variable-name-face)
    (,(hlsl-ppre hlsl-const-list)     . 'font-lock-constant-face)
    (,(hlsl-ppre hlsl-builtin-list)   . 'font-lock-builtin-face)
    )
  "syntax highlight for HLSL"
  )

;;font-lock-type-face
;;font-lock-builtin-face
;;font-lock-variable-name-face
;;font-lock-constant-face

(defvar hlsl-font-lock-keywords hlsl-font-lock-keywords-1
  "Default highlighting expressions for HLSL mode")

;; comment syntax
(defvar hlsl-mode-syntax-table
  (let ((syntable  (make-syntax-table)))
    ;;comment style /*..*/
    (modify-syntax-entry ?/ ". 124b" syntable)
    (modify-syntax-entry ?* ". 23" syntable)
    (modify-syntax-entry ?\n "> b" syntable)
    (modify-syntax-entry ?_ "w" syntable)
    syntable)
  "Syntax table for hlsl-mode")


;; menu
(easy-menu-define hlsl-menu hlsl-mode-map
  "HLSL Menu"
    `("HLSL"
      ["Comment Out Region"     comment-region
       (c-fn-region-is-active-p)]
      ["Uncomment Region"       (comment-region (region-beginning)
						(region-end) '(4))
       (c-fn-region-is-active-p)]
      ["Indent Expression"      c-indent-exp
       (memq (char-after) '(?\( ?\[ ?\{))]
      ["Indent Line or Region"  c-indent-line-or-region t]
      ["Fill Comment Paragraph" c-fill-paragraph t]
      "----"
      ["Backward Statement"     c-beginning-of-statement t]
      ["Forward Statement"      c-end-of-statement t]
      "----"
      ["Up Conditional"         c-up-conditional t]
      ["Backward Conditional"   c-backward-conditional t]
      ["Forward Conditional"    c-forward-conditional t]
      "----"
      ["Backslashify"           c-backslash-region (c-fn-region-is-active-p)]
      ))


;;;###autoload
(define-derived-mode hlsl-mode prog-mode "HLSL"
  "Major mode for editing HLSL shader files."
  (c-initialize-cc-mode t)
  (setq abbrev-mode t)
  (c-init-language-vars-for 'c-mode)
  (c-common-init 'c-mode)
  (cc-imenu-init cc-imenu-c++-generic-expression)
  (set (make-local-variable 'font-lock-defaults) '(hlsl-font-lock-keywords))

  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'comment-padding) "")
  (easy-menu-add hlsl-menu)
  (add-to-list 'align-c++-modes 'glsl-mode)
  (c-run-mode-hooks 'c-mode-common-hook)
  (run-mode-hooks 'hlsl-mode-hook)
  :after-hook (progn (c-make-noise-macro-regexps)
		     (c-make-macro-with-semi-re)
		     (c-update-modeline))
  )

(provide 'hlsl-mode)
;;; hlsls-mode.el ends here
