# 音乐标签编辑器

独立 macOS Cocoa 应用，用于本地编辑 MP3、FLAC、M4A、AAC、WAV 与 AIFF 音频的常见标签和封面。除歌曲名、艺人、专辑艺人、专辑名、曲目/碟片编号、年份、流派和作曲者外，也提供调式、和声走向、BPM、歌词与备注字段。

## 构建

```sh
zsh build.sh
```

产物位于 `build/音乐标签编辑器.app`。当前构建面向 Apple Silicon Mac，最低系统版本为 macOS 12。构建前需将 GitHub Release 中的 `ffmpeg-arm64` 放入 `vendor/ffmpeg-arm64`（该 63 MB 第三方二进制不放在 Git 源码树中）。

## 使用

选择或拖入文件，在列表中选中单首或多首歌曲；右侧修改标签、添加/移除封面，最后点击“保存更改”。保存会直接更新音频文件；修改歌曲名称时也会同步更新文件名。应用不联网。

标签读写由随附的 FFmpeg 完成，音频流以 stream copy 保留，不重新编码。AAC 裸流没有通用标签容器，因此编辑会被拒绝。WAV 封面使用 RIFF/ID3 APIC 标签保存；不同播放器对 WAV 内嵌封面的识别情况可能不同。AIFF 的封面支持取决于其容器实现；遇到无法安全写入的情况时会保留原文件。

## 下载

GitHub Releases 提供 Apple Silicon 版压缩包。下载后解压，将“音乐标签编辑器.app”拖入“应用程序”即可。此版本未做 Apple Developer ID 公证，首次打开时可能需要在 Finder 中右键选择“打开”。

## 第三方组件

应用包内附带 FFmpeg arm64 可执行文件。该 FFmpeg 版本依据 GNU GPL v3 或更高版本发布，许可证文本见 `vendor/FFmpeg-LICENSE.txt`；FFmpeg 版本和构建来源见 `vendor/FFmpeg-BUILD.txt`。FFmpeg 项目地址：https://ffmpeg.org/ 。
