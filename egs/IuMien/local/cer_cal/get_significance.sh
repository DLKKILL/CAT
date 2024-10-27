true_path=/home/dlk/code/asr/cat/egs/MightLJSpeech/data/src/test/text
exp1_path=/home/dlk/code/asr/cat/egs/MightLJSpeech/paper-exp/Whistle-sub-FT/decode/test/ac1.0_lm0.4_wip0.0.hyp
exp2_path=/home/dlk/code/asr/cat/egs/MightLJSpeech/paper-exp/Wav2vec2-cv10-phoneme-FT/decode/test/ac1.0_lm0.8_wip0.0.hyp
cache_path=/home/dlk/code/asr/cat/egs/MightLJSpeech/significance_cache/M1-M3-with-lm
if [ ! -d "$cache_path" ]; then
    mkdir -p "$cache_path"
    echo "文件夹 '$cache_path' 已创建。"
fi
mode=mp
chmod +x local/cer_cal/p_cal.sh
local/cer_cal/p_cal.sh $true_path $cache_path $mode $exp1_path $exp2_path