#import <Cocoa/Cocoa.h>
#include <stdint.h>

static uint32_t ReadLE32(const uint8_t *bytes) { return (uint32_t)bytes[0] | ((uint32_t)bytes[1]<<8) | ((uint32_t)bytes[2]<<16) | ((uint32_t)bytes[3]<<24); }
static uint32_t ReadBE32(const uint8_t *bytes) { return ((uint32_t)bytes[0]<<24) | ((uint32_t)bytes[1]<<16) | ((uint32_t)bytes[2]<<8) | (uint32_t)bytes[3]; }
static NSData *LE32Data(uint32_t value) { uint8_t b[4]={(uint8_t)value,(uint8_t)(value>>8),(uint8_t)(value>>16),(uint8_t)(value>>24)}; return [NSData dataWithBytes:b length:4]; }
static NSData *BE32Data(uint32_t value) { uint8_t b[4]={(uint8_t)(value>>24),(uint8_t)(value>>16),(uint8_t)(value>>8),(uint8_t)value}; return [NSData dataWithBytes:b length:4]; }
static NSData *SyncSafe32Data(uint32_t value) { uint8_t b[4]={(uint8_t)((value>>21)&0x7f),(uint8_t)((value>>14)&0x7f),(uint8_t)((value>>7)&0x7f),(uint8_t)(value&0x7f)}; return [NSData dataWithBytes:b length:4]; }
static uint32_t ReadSyncSafe32(const uint8_t *b) { return ((uint32_t)(b[0]&0x7f)<<21)|((uint32_t)(b[1]&0x7f)<<14)|((uint32_t)(b[2]&0x7f)<<7)|(uint32_t)(b[3]&0x7f); }

@interface AudioItem : NSObject
@property(nonatomic, strong) NSURL *url;
@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *artist;
@property(nonatomic, copy) NSString *albumArtist;
@property(nonatomic, copy) NSString *album;
@property(nonatomic, copy) NSString *year;
@property(nonatomic, copy) NSString *track;
@property(nonatomic, copy) NSString *disc;
@property(nonatomic, copy) NSString *genre;
@property(nonatomic, copy) NSString *composer;
@property(nonatomic, copy) NSString *key;
@property(nonatomic, copy) NSString *chords;
@property(nonatomic, copy) NSString *bpm;
@property(nonatomic, copy) NSString *lyrics;
@property(nonatomic, copy) NSString *comment;
@property(nonatomic, strong) NSImage *cover;
@property(nonatomic, strong) NSData *coverData;
@property(nonatomic, copy) NSString *status;
@end
@implementation AudioItem
@end

@interface EditableTextField : NSTextField
@end
@implementation EditableTextField
- (void)mouseDown:(NSEvent *)event {
    if (self.enabled) [self.window makeFirstResponder:self];
    [super mouseDown:event];
    if (self.enabled) [self selectText:nil];
}
@end

@interface CenteredTableCell : NSTextFieldCell
@end
@implementation CenteredTableCell
- (NSRect)titleRectForBounds:(NSRect)bounds {
    NSRect textRect=[super titleRectForBounds:bounds];
    textRect.origin.y=NSMidY(bounds)-NSHeight(textRect)/2.0;
    return textRect;
}
@end

@interface CoverImageView : NSImageView
@property(nonatomic, weak) id clickTarget;
@property(nonatomic) SEL clickAction;
@end
@implementation CoverImageView
- (void)mouseDown:(NSEvent *)event {
    [super mouseDown:event];
    if (self.clickTarget && self.clickAction) [NSApp sendAction:self.clickAction to:self.clickTarget from:self];
}
@end

@interface DropView : NSView <NSDraggingDestination>
@property(nonatomic, copy) void (^onFiles)(NSArray<NSURL *> *);
@end
@implementation DropView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.wantsLayer = YES; self.layer.cornerRadius = 10;
        self.layer.backgroundColor = [NSColor colorWithSRGBRed:0.12 green:0.13 blue:0.15 alpha:1].CGColor;
        self.layer.borderWidth = 1; self.layer.borderColor = [NSColor colorWithSRGBRed:0.22 green:0.24 blue:0.27 alpha:1].CGColor;
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
        NSTextField *hint = [NSTextField labelWithString:@"拖入音乐文件，或点击“添加文件”；左侧列表也可接收文件"];
        hint.font = [NSFont systemFontOfSize:14 weight:NSFontWeightMedium]; hint.textColor = [NSColor colorWithSRGBRed:0.63 green:0.68 blue:0.73 alpha:1];
        hint.translatesAutoresizingMaskIntoConstraints = NO; [self addSubview:hint];
        [NSLayoutConstraint activateConstraints:@[[hint.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],[hint.centerYAnchor constraintEqualToAnchor:self.centerYAnchor]]];
    } return self;
}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender { return NSDragOperationCopy; }
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray *urls = [sender.draggingPasteboard readObjectsForClasses:@[NSURL.class] options:@{NSPasteboardURLReadingFileURLsOnlyKey:@YES}];
    if (urls.count && self.onFiles) self.onFiles(urls); return urls.count > 0;
}
@end

@interface MusicTableView : NSTableView <NSDraggingDestination>
@property(nonatomic, copy) void (^onFiles)(NSArray<NSURL *> *);
@end
@implementation MusicTableView
- (instancetype)initWithFrame:(NSRect)frame {
    if ((self=[super initWithFrame:frame])) [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    return self;
}
- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender { return NSDragOperationCopy; }
- (NSDragOperation)draggingUpdated:(id<NSDraggingInfo>)sender { return NSDragOperationCopy; }
- (BOOL)prepareForDragOperation:(id<NSDraggingInfo>)sender { return YES; }
- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls=[sender.draggingPasteboard readObjectsForClasses:@[NSURL.class] options:@{NSPasteboardURLReadingFileURLsOnlyKey:@YES}];
    if (urls.count && self.onFiles) self.onFiles(urls);
    return urls.count>0;
}
@end

@interface AppDelegate : NSObject <NSApplicationDelegate,NSTableViewDataSource,NSTableViewDelegate>
@end
@implementation AppDelegate {
    NSWindow *_window; NSTableView *_table; NSScrollView *_tableScroll; NSMutableArray<AudioItem *> *_items;
    NSMutableDictionary<NSString *, NSTextField *> *_fields; NSImageView *_coverView;
    NSTextField *_status; NSButton *_saveButton; NSData *_newCover; BOOL _removeCover; BOOL _isSaving;
}
- (NSColor *)color:(CGFloat)r g:(CGFloat)g b:(CGFloat)b { return [NSColor colorWithSRGBRed:r green:g blue:b alpha:1]; }
- (void)styleLabel:(NSTextField *)label secondary:(BOOL)secondary {
    label.textColor = secondary ? [self color:0.61 g:0.66 b:0.71] : [self color:0.90 g:0.92 b:0.94];
}
- (void)styleActionButton:(NSButton *)button accent:(BOOL)accent {
    button.bezelStyle = NSBezelStyleRounded;
    button.font = [NSFont systemFontOfSize:12 weight:NSFontWeightSemibold];
    button.contentTintColor = accent ? [self color:0.17 g:0.82 b:0.90] : [self color:0.82 g:0.85 b:0.88];
}
- (void)applicationDidFinishLaunching:(NSNotification *)n { _items=[NSMutableArray array]; _fields=[NSMutableDictionary dictionary]; [self makeEditMenu]; [self makeUI]; }
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)s { return YES; }
- (void)application:(NSApplication *)a openURLs:(NSArray<NSURL *> *)urls { [self addURLs:urls]; }
- (NSString *)ffmpegPath { return [[NSBundle mainBundle] pathForResource:@"ffmpeg-arm64" ofType:nil inDirectory:@"bin"]; }
- (NSArray<NSString *> *)supportedExtensions { return @[@"mp3",@"flac",@"m4a",@"aac",@"wav",@"aiff",@"aif"]; }
- (void)makeEditMenu {
    NSMenu *mainMenu=[[NSMenu alloc] initWithTitle:@""];
    NSMenuItem *editItem=[[NSMenuItem alloc] initWithTitle:@"编辑" action:nil keyEquivalent:@""];
    NSMenu *editMenu=[[NSMenu alloc] initWithTitle:@"编辑"];
    for (NSArray *entry in @[@[@"撤销",@"undo:",@"z"],@[@"重做",@"redo:",@"Z"],@[@"剪切",@"cut:",@"x"],@[@"拷贝",@"copy:",@"c"],@[@"粘贴",@"paste:",@"v"],@[@"全选",@"selectAll:",@"a"]]) {
        NSMenuItem *item=[[NSMenuItem alloc] initWithTitle:entry[0] action:NSSelectorFromString(entry[1]) keyEquivalent:entry[2]];
        item.keyEquivalentModifierMask=NSEventModifierFlagCommand; [editMenu addItem:item];
    }
    editItem.submenu=editMenu; [mainMenu addItem:editItem]; NSApp.mainMenu=mainMenu;
}
- (void)makeUI {
    _window=[[NSWindow alloc] initWithContentRect:NSMakeRect(0,0,1120,760) styleMask:NSWindowStyleMaskTitled|NSWindowStyleMaskClosable|NSWindowStyleMaskMiniaturizable|NSWindowStyleMaskResizable backing:NSBackingStoreBuffered defer:NO];
    _window.title=@"音乐标签编辑器 2.3"; _window.minSize=NSMakeSize(920,620); _window.appearance=[NSAppearance appearanceNamed:NSAppearanceNameDarkAqua]; [_window center];
    NSView *root=_window.contentView; root.wantsLayer=YES; root.layer.backgroundColor=[self color:0.075 g:0.082 b:0.095].CGColor;
    NSStackView *main=[NSStackView stackViewWithViews:@[]]; main.orientation=NSUserInterfaceLayoutOrientationVertical; main.alignment= NSLayoutAttributeLeading; main.spacing=12; main.translatesAutoresizingMaskIntoConstraints=NO; [root addSubview:main];
    NSTextField *heading=[NSTextField labelWithString:@"音乐标签编辑器"]; heading.font=[NSFont systemFontOfSize:26 weight:NSFontWeightBold]; [self styleLabel:heading secondary:NO];
    NSTextField *sub=[NSTextField labelWithString:@"在本机编辑歌曲信息与封面。文件只会在点击“保存更改”后写入。"];
    sub.font=[NSFont systemFontOfSize:12]; [self styleLabel:sub secondary:YES];
    DropView *drop=[[DropView alloc] initWithFrame:NSZeroRect]; drop.translatesAutoresizingMaskIntoConstraints=NO; __weak typeof(self) weak=self; drop.onFiles=^(NSArray *u){[weak addURLs:u];};
    NSButton *add=[NSButton buttonWithTitle:@"添加文件" target:self action:@selector(addFiles:)];
    NSButton *save=[NSButton buttonWithTitle:@"保存更改" target:self action:@selector(saveChanges:)]; save.keyEquivalent=@"s"; _saveButton=save;
    NSButton *coverButton=[NSButton buttonWithTitle:@"选择封面图片" target:self action:@selector(chooseCover:)];
    NSButton *clear=[NSButton buttonWithTitle:@"移除列表" target:self action:@selector(clearList:)];
    [self styleActionButton:add accent:NO]; [self styleActionButton:save accent:YES]; [self styleActionButton:coverButton accent:NO]; [self styleActionButton:clear accent:NO];
    NSStackView *actions=[NSStackView stackViewWithViews:@[add,save,coverButton,clear]]; actions.orientation=NSUserInterfaceLayoutOrientationHorizontal; actions.spacing=8;
    [self buildTable]; _tableScroll=[[NSScrollView alloc] init]; _tableScroll.documentView=_table; _tableScroll.hasVerticalScroller=YES; _tableScroll.hasHorizontalScroller=YES; _tableScroll.autohidesScrollers=NO; _tableScroll.scrollerStyle=NSScrollerStyleLegacy; _tableScroll.borderType=NSNoBorder; _tableScroll.drawsBackground=YES; _tableScroll.backgroundColor=[self color:0.105 g:0.115 b:0.13];
    CGFloat tableContentWidth=0; for (NSTableColumn *column in _table.tableColumns) tableContentWidth+=column.width;
    _table.frame=NSMakeRect(0,0,tableContentWidth,600); _table.autoresizingMask=NSViewHeightSizable;
    NSView *editor=[self editorView]; NSScrollView *editorScroll=[[NSScrollView alloc] initWithFrame:NSZeroRect]; editorScroll.documentView=editor; editorScroll.hasVerticalScroller=YES; editorScroll.autohidesScrollers=NO; editorScroll.scrollerStyle=NSScrollerStyleLegacy; editorScroll.borderType=NSNoBorder; editorScroll.drawsBackground=YES; editorScroll.backgroundColor=[self color:0.12 g:0.13 b:0.15];
    NSStackView *split=[NSStackView stackViewWithViews:@[_tableScroll,editorScroll]]; split.orientation=NSUserInterfaceLayoutOrientationHorizontal; split.alignment=NSLayoutAttributeTop; split.distribution=NSStackViewDistributionFill; split.spacing=10; split.translatesAutoresizingMaskIntoConstraints=NO;
    [editorScroll.widthAnchor constraintEqualToConstant:440].active=YES;
    _status=[NSTextField labelWithString:@"选择或拖入音乐文件开始。支持 MP3、FLAC、M4A/AAC、WAV、AIFF。"]; _status.font=[NSFont systemFontOfSize:11]; [self styleLabel:_status secondary:YES];
    [main addArrangedSubview:heading]; [main addArrangedSubview:sub]; [main addArrangedSubview:drop]; [main addArrangedSubview:actions]; [main addArrangedSubview:split]; [main addArrangedSubview:_status];
    [NSLayoutConstraint activateConstraints:@[[main.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:20],[main.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-20],[main.topAnchor constraintEqualToAnchor:root.topAnchor constant:18],[main.bottomAnchor constraintEqualToAnchor:root.bottomAnchor constant:-16],[drop.widthAnchor constraintEqualToAnchor:main.widthAnchor],[drop.heightAnchor constraintEqualToConstant:56],[split.widthAnchor constraintEqualToAnchor:main.widthAnchor],[split.heightAnchor constraintGreaterThanOrEqualToConstant:430],[_tableScroll.widthAnchor constraintGreaterThanOrEqualToConstant:480],[_status.widthAnchor constraintEqualToAnchor:main.widthAnchor]]];
    [root layoutSubtreeIfNeeded]; [self updateTableDocumentSize];
    [_window makeKeyAndOrderFront:nil]; [NSApp activateIgnoringOtherApps:YES];
}
- (void)buildTable {
    MusicTableView *table=[[MusicTableView alloc] initWithFrame:NSZeroRect]; __weak typeof(self) weakSelf=self; table.onFiles=^(NSArray<NSURL *> *urls){ [weakSelf addURLs:urls]; }; _table=table; _table.delegate=self; _table.dataSource=self; _table.allowsMultipleSelection=YES; _table.usesAlternatingRowBackgroundColors=NO; _table.backgroundColor=[self color:0.105 g:0.115 b:0.13]; _table.gridColor=[self color:0.19 g:0.21 b:0.24]; _table.rowHeight=36; _table.selectionHighlightStyle= NSTableViewSelectionHighlightStyleRegular; _table.columnAutoresizingStyle=NSTableViewNoColumnAutoresizing;
    for (NSArray *spec in @[@[@"title",@"歌曲名称",@210],@[@"artist",@"艺人",@130],@[@"albumArtist",@"专辑艺人",@140],@[@"album",@"专辑名称",@160],@[@"year",@"年份",@70],@[@"track",@"曲目",@65],@[@"disc",@"碟片",@65],@[@"genre",@"流派",@100],@[@"composer",@"作曲者",@120],@[@"key",@"调式",@80],@[@"chords",@"和声走向",@145],@[@"bpm",@"BPM",@70],@[@"format",@"格式",@70]]) { NSTableColumn *c=[[NSTableColumn alloc] initWithIdentifier:spec[0]]; c.title=spec[1]; c.width=[spec[2] doubleValue]; c.resizingMask=NSTableColumnNoResizing; CenteredTableCell *dataCell=[[CenteredTableCell alloc] initTextCell:@""]; dataCell.editable=NO; c.dataCell=dataCell; c.headerCell.textColor=[self color:0.66 g:0.70 b:0.75]; c.headerCell.font=[NSFont systemFontOfSize:12 weight:NSFontWeightSemibold]; [_table addTableColumn:c]; }
}
- (void)updateTableDocumentSize {
    if (!_table || !_tableScroll) return;
    CGFloat width=0; for (NSTableColumn *column in _table.tableColumns) width+=column.width;
    CGFloat visibleHeight=NSHeight(_tableScroll.contentView.bounds);
    CGFloat headerHeight=NSHeight(_table.headerView.frame);
    CGFloat contentHeight=headerHeight+_items.count*_table.rowHeight;
    [_table setFrameSize:NSMakeSize(width,MAX(visibleHeight,contentHeight))];
}
- (NSData *)id3CoverFrameForImageData:(NSData *)imageData {
    if (!imageData.length) return nil;
    const uint8_t *bytes=imageData.bytes;
    NSString *mime=@"image/jpeg";
    if (imageData.length>=8 && !memcmp(bytes,"\x89PNG\r\n\x1a\n",8)) mime=@"image/png";
    else if (imageData.length>=12 && !memcmp(bytes,"RIFF",4) && !memcmp(bytes+8,"WEBP",4)) mime=@"image/webp";
    NSMutableData *body=[NSMutableData data]; uint8_t encoding=0,pictureType=3,terminator=0;
    [body appendBytes:&encoding length:1]; [body appendData:[mime dataUsingEncoding:NSASCIIStringEncoding]]; [body appendBytes:&terminator length:1]; [body appendBytes:&pictureType length:1]; [body appendBytes:&terminator length:1]; [body appendData:imageData];
    if (body.length>UINT32_MAX) return nil;
    NSMutableData *frame=[NSMutableData dataWithBytes:"APIC" length:4]; [frame appendData:BE32Data((uint32_t)body.length)]; uint8_t flags[2]={0,0}; [frame appendBytes:flags length:2]; [frame appendData:body];
    NSMutableData *tag=[NSMutableData dataWithBytes:"ID3\x03\x00\x00" length:6]; [tag appendData:SyncSafe32Data((uint32_t)frame.length)]; [tag appendData:frame];
    NSMutableData *chunk=[NSMutableData dataWithBytes:"ID3 " length:4]; [chunk appendData:LE32Data((uint32_t)tag.length)]; [chunk appendData:tag]; if (tag.length&1) [chunk appendBytes:&terminator length:1];
    return chunk;
}
- (NSData *)extractID3CoverFromTagData:(NSData *)tagData {
    if (tagData.length<10 || memcmp(tagData.bytes,"ID3",3)!=0) return nil;
    const uint8_t *bytes=tagData.bytes; uint32_t tagSize=ReadSyncSafe32(bytes+6); NSUInteger limit=MIN(tagData.length,10+(NSUInteger)tagSize),offset=10;
    while (offset+10<=limit) {
        const uint8_t *frame=bytes+offset; if (!memcmp(frame,"\0\0\0\0",4)) break;
        uint32_t frameSize=(bytes[3]==4) ? ReadSyncSafe32(frame+4) : ReadBE32(frame+4);
        if (!frameSize || offset+10+(NSUInteger)frameSize>limit) break;
        if (!memcmp(frame,"APIC",4) && frameSize>=5) {
            const uint8_t *body=frame+10; NSUInteger bodyLength=frameSize,position=1;
            while (position<bodyLength && body[position]) position++;
            if (position+2>=bodyLength) return nil;
            position+=2; uint8_t encoding=body[0];
            if (encoding==1 || encoding==2) { while (position+1<bodyLength && (body[position] || body[position+1])) position+=2; if (position+1<bodyLength) position+=2; }
            else { while (position<bodyLength && body[position]) position++; if (position<bodyLength) position++; }
            if (position<bodyLength) return [NSData dataWithBytes:body+position length:bodyLength-position];
            return nil;
        }
        offset+=10+(NSUInteger)frameSize;
    }
    return nil;
}
- (NSData *)extractWAVCoverAtPath:(NSString *)path {
    NSFileHandle *file=[NSFileHandle fileHandleForReadingAtPath:path]; if (!file) return nil;
    @try {
        unsigned long long length=[file seekToEndOfFile]; if (length<12) { [file closeFile]; return nil; }
        [file seekToFileOffset:0]; NSData *header=[file readDataOfLength:12]; const uint8_t *h=header.bytes;
        if (header.length<12 || memcmp(h,"RIFF",4) || memcmp(h+8,"WAVE",4)) { [file closeFile]; return nil; }
        unsigned long long offset=12;
        while (offset+8<=length) {
            [file seekToFileOffset:offset]; NSData *chunkHeader=[file readDataOfLength:8]; if (chunkHeader.length<8) break;
            const uint8_t *c=chunkHeader.bytes; uint32_t size=ReadLE32(c+4); unsigned long long payload=offset+8,next=payload+size+(size&1);
            if (next>length) break;
            if ((!memcmp(c,"ID3 ",4) || !memcmp(c,"id3 ",4)) && size<=67108864) { NSData *tag=[file readDataOfLength:size]; NSData *cover=[self extractID3CoverFromTagData:tag]; if (cover) { [file closeFile]; return cover; } }
            offset=next;
        }
    } @catch (__unused NSException *exception) { }
    [file closeFile]; return nil;
}
- (BOOL)rewriteWAVAtPath:(NSString *)path coverData:(NSData *)coverData error:(NSError **)error {
    NSFileManager *fm=[NSFileManager defaultManager]; NSString *rewrite=[path stringByAppendingString:@".riff-rewrite"];
    [fm removeItemAtPath:rewrite error:nil];
    NSFileHandle *source=[NSFileHandle fileHandleForReadingAtPath:path];
    if (!source) { if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:10 userInfo:@{NSLocalizedDescriptionKey:@"无法读取 WAV 临时文件。"}]; return NO; }
    @try {
        unsigned long long sourceLength=[source seekToEndOfFile]; [source seekToFileOffset:0]; NSData *header=[source readDataOfLength:12];
        if (header.length<12 || memcmp(header.bytes,"RIFF",4) || memcmp((const uint8_t *)header.bytes+8,"WAVE",4)) { [source closeFile]; if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:11 userInfo:@{NSLocalizedDescriptionKey:@"此 WAV 使用了暂不支持写入封面的容器结构。"}]; return NO; }
        [fm createFileAtPath:rewrite contents:nil attributes:nil]; NSFileHandle *output=[NSFileHandle fileHandleForWritingAtPath:rewrite]; if (!output) { [source closeFile]; return NO; }
        [output writeData:header]; unsigned long long offset=12;
        while (offset+8<=sourceLength) {
            [source seekToFileOffset:offset]; NSData *chunkHeader=[source readDataOfLength:8]; if (chunkHeader.length<8) @throw [NSException exceptionWithName:@"WAVRead" reason:@"WAV 数据块头损坏。" userInfo:nil];
            const uint8_t *c=chunkHeader.bytes; uint32_t chunkSize=ReadLE32(c+4); unsigned long long payload=offset+8,next=payload+chunkSize+(chunkSize&1);
            if (next>sourceLength) @throw [NSException exceptionWithName:@"WAVRead" reason:@"WAV 数据块长度超出文件大小。" userInfo:nil];
            BOOL isID3=(!memcmp(c,"ID3 ",4) || !memcmp(c,"id3 ",4));
            if (!isID3) {
                [output writeData:chunkHeader]; [source seekToFileOffset:payload]; unsigned long long remaining=chunkSize+(chunkSize&1);
                while (remaining) { NSUInteger amount=(NSUInteger)MIN(remaining,1024*1024); NSData *part=[source readDataOfLength:amount]; if (part.length!=amount) @throw [NSException exceptionWithName:@"WAVRead" reason:@"WAV 数据读取不完整。" userInfo:nil]; [output writeData:part]; remaining-=part.length; }
            }
            offset=next;
        }
        if (offset!=sourceLength) @throw [NSException exceptionWithName:@"WAVRead" reason:@"WAV 文件末尾包含无法识别的数据块。" userInfo:nil];
        NSData *coverChunk=[self id3CoverFrameForImageData:coverData]; if (coverData && !coverChunk) @throw [NSException exceptionWithName:@"WAVCover" reason:@"封面图片无法封装为 WAV 图片标签。" userInfo:nil]; if (coverChunk) [output writeData:coverChunk];
        unsigned long long outputLength=[output offsetInFile]; if (outputLength<8 || outputLength-8>UINT32_MAX) @throw [NSException exceptionWithName:@"WAVSize" reason:@"WAV 文件超过 RIFF 格式的大小上限。" userInfo:nil];
        [output seekToFileOffset:4]; [output writeData:LE32Data((uint32_t)(outputLength-8))]; [output synchronizeFile]; [output closeFile]; [source closeFile];
        [fm removeItemAtPath:path error:nil]; NSError *moveError=nil;
        if (![fm moveItemAtPath:rewrite toPath:path error:&moveError]) { if (error) *error=moveError; return NO; }
        return YES;
    } @catch (NSException *exception) {
        @try { [source closeFile]; } @catch (__unused NSException *ignored) { }
        [fm removeItemAtPath:rewrite error:nil];
        if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:12 userInfo:@{NSLocalizedDescriptionKey:exception.reason ?: @"无法更新 WAV 封面。"}];
        return NO;
    }
}
- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row { return NO; }
- (void)tableView:(NSTableView *)tableView willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if ([cell isKindOfClass:NSTextFieldCell.class]) { NSTextFieldCell *textCell=cell; textCell.textColor=[self color:0.85 g:0.88 b:0.91]; textCell.font=[NSFont systemFontOfSize:12]; }
}
- (NSView *)editorView {
    NSView *v=[[NSView alloc] initWithFrame:NSMakeRect(0,0,440,980)];
    v.wantsLayer=YES; v.layer.backgroundColor=[self color:0.12 g:0.13 b:0.15].CGColor;
    NSTextField *h=[NSTextField labelWithString:@"歌曲与专辑信息"]; h.font=[NSFont systemFontOfSize:19 weight:NSFontWeightSemibold]; h.frame=NSMakeRect(16,936,390,30); [self styleLabel:h secondary:NO]; [v addSubview:h];
    NSTextField *hint=[NSTextField labelWithString:@"先在左侧选择歌曲。多选时，保存会将右侧内容应用到全部选中歌曲。"];
    hint.stringValue=@"保存歌曲名称时会同步重命名文件；多选时应用到全部选中歌曲。"; [self styleLabel:hint secondary:YES]; hint.font=[NSFont systemFontOfSize:11]; hint.frame=NSMakeRect(16,914,405,18); [v addSubview:hint];
    NSArray *names=@[@[@"title",@"歌曲名称"],@[@"artist",@"艺人"],@[@"albumArtist",@"专辑艺人"],@[@"album",@"专辑名称"],@[@"year",@"发行年份"],@[@"track",@"曲目编号"],@[@"disc",@"碟片编号"],@[@"genre",@"流派"],@[@"composer",@"作曲者"],@[@"key",@"歌曲调式"],@[@"chords",@"和声走向"],@[@"bpm",@"BPM / 速度"],@[@"lyrics",@"歌词"],@[@"comment",@"备注"]];
    CGFloat y=880;
    for (NSArray *pair in names) { NSTextField *label=[NSTextField labelWithString:pair[1]]; label.font=[NSFont systemFontOfSize:12]; label.frame=NSMakeRect(16,y,100,24); [self styleLabel:label secondary:YES]; [v addSubview:label]; EditableTextField *field=[[EditableTextField alloc] initWithFrame:NSMakeRect(120,y-2,288,29)]; field.placeholderString=pair[1]; field.enabled=YES; field.editable=YES; field.selectable=YES; field.bezeled=YES; field.drawsBackground=YES; field.backgroundColor=[self color:0.16 g:0.175 b:0.195]; field.textColor=[self color:0.91 g:0.93 b:0.95]; field.font=[NSFont systemFontOfSize:13]; field.focusRingType=NSFocusRingTypeDefault; [v addSubview:field]; _fields[pair[0]]=field; y-=40; }
    NSView *coverPanel=[[NSView alloc] initWithFrame:NSMakeRect(10,32,416,270)]; coverPanel.wantsLayer=YES; coverPanel.layer.backgroundColor=[self color:0.145 g:0.16 b:0.18].CGColor; coverPanel.layer.cornerRadius=10; coverPanel.layer.borderWidth=1; coverPanel.layer.borderColor=[self color:0.22 g:0.24 b:0.27].CGColor; [v addSubview:coverPanel positioned:NSWindowBelow relativeTo:nil];
    NSTextField *coverTitle=[NSTextField labelWithString:@"专辑封面"]; coverTitle.font=[NSFont systemFontOfSize:16 weight:NSFontWeightSemibold]; coverTitle.frame=NSMakeRect(16,308,380,24); [self styleLabel:coverTitle secondary:NO]; [v addSubview:coverTitle];
    CoverImageView *coverView=[[CoverImageView alloc] initWithFrame:NSMakeRect(16,120,164,164)]; coverView.imageScaling=NSImageScaleProportionallyUpOrDown; coverView.imageFrameStyle=NSImageFrameGrayBezel; coverView.wantsLayer=YES; coverView.layer.backgroundColor=[self color:0.09 g:0.10 b:0.12].CGColor; coverView.layer.cornerRadius=8; coverView.layer.borderColor=[self color:0.27 g:0.30 b:0.33].CGColor; coverView.layer.borderWidth=1; coverView.clickTarget=self; coverView.clickAction=@selector(chooseCover:); _coverView=coverView; [v addSubview:_coverView];
    NSButton *pick=[NSButton buttonWithTitle:@"添加 / 更换封面图片…" target:self action:@selector(chooseCover:)]; pick.frame=NSMakeRect(196,244,210,32); [self styleActionButton:pick accent:YES]; [v addSubview:pick];
    NSButton *remove=[NSButton buttonWithTitle:@"移除现有封面" target:self action:@selector(removeCover:)]; remove.frame=NSMakeRect(196,200,170,30); [self styleActionButton:remove accent:NO]; [v addSubview:remove];
    NSTextField *coverHint=[NSTextField labelWithString:@"支持 JPG、PNG、WebP。点击封面框或按钮选择图片，保存时嵌入音频文件。"];
    [self styleLabel:coverHint secondary:YES]; coverHint.font=[NSFont systemFontOfSize:11]; coverHint.frame=NSMakeRect(16,82,390,20); [v addSubview:coverHint];
    NSTextField *note=[NSTextField labelWithString:@"留空字段也会写为空；不想改动的字段请保留原值。"];
    [self styleLabel:note secondary:YES]; note.font=[NSFont systemFontOfSize:11]; note.frame=NSMakeRect(16,52,390,20); [v addSubview:note]; return v;
}
- (void)addFiles:(id)sender { NSOpenPanel *p=[NSOpenPanel openPanel]; p.allowsMultipleSelection=YES; p.canChooseDirectories=NO; p.allowedFileTypes=[self supportedExtensions]; if ([p runModal]==NSModalResponseOK) [self addURLs:p.URLs]; }
- (void)addURLs:(NSArray<NSURL *> *)urls {
    NSMutableSet *known=[NSMutableSet set]; for (AudioItem *i in _items) [known addObject:i.url.path];
    NSMutableArray<AudioItem *> *pending=[NSMutableArray array];
    for (NSURL *u in urls) { if (![self.supportedExtensions containsObject:u.pathExtension.lowercaseString] || [known containsObject:u.path]) continue; AudioItem *i=[AudioItem new]; i.url=u; i.title=u.lastPathComponent.stringByDeletingPathExtension; i.status=@"正在读取标签…"; [_items addObject:i]; [pending addObject:i]; [known addObject:u.path]; }
    [_table reloadData]; [self updateTableDocumentSize];
    if (pending.count) {
        NSInteger firstNewRow=(NSInteger)(_items.count-pending.count);
        [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:firstNewRow] byExtendingSelection:NO];
        [_table scrollRowToVisible:firstNewRow];
        [self refreshEditorFromSelection];
    } else if (_items.count && _table.selectedRowIndexes.count==0) {
        [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
        [self refreshEditorFromSelection];
    }
    _status.stringValue=[NSString stringWithFormat:@"已添加 %lu 首，正在读取标签…",(unsigned long)pending.count];
    if (!pending.count) {
        BOOL supported=NO; for (NSURL *url in urls) if ([self.supportedExtensions containsObject:url.pathExtension.lowercaseString]) { supported=YES; break; }
        _status.stringValue=supported ? [NSString stringWithFormat:@"拖入的歌曲已在列表中（共 %lu 首）。",(unsigned long)_items.count] : @"没有识别到支持的音乐文件。请拖入 MP3、FLAC、M4A、AAC、WAV 或 AIFF 文件。";
        return;
    }
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        for (AudioItem *placeholder in pending) {
            AudioItem *loaded=[self readItem:placeholder.url];
            dispatch_async(dispatch_get_main_queue(), ^{
                placeholder.title=loaded.title; placeholder.artist=loaded.artist; placeholder.albumArtist=loaded.albumArtist; placeholder.album=loaded.album; placeholder.year=loaded.year; placeholder.track=loaded.track; placeholder.disc=loaded.disc; placeholder.genre=loaded.genre; placeholder.composer=loaded.composer; placeholder.key=loaded.key; placeholder.chords=loaded.chords; placeholder.bpm=loaded.bpm; placeholder.lyrics=loaded.lyrics; placeholder.comment=loaded.comment; placeholder.cover=loaded.cover; placeholder.coverData=loaded.coverData; placeholder.status=@"已读取";
                [_table reloadData]; if (_table.selectedRowIndexes.count && _items[_table.selectedRowIndexes.firstIndex]==placeholder) [self refreshEditorFromSelection];
                BOOL stillReading=NO; for (AudioItem *item in pending) if ([item.status isEqual:@"正在读取标签…"]) { stillReading=YES; break; }
                if (!stillReading) _status.stringValue=[NSString stringWithFormat:@"已读取 %lu 首歌曲信息。可在右侧编辑后点击“保存更改”。",(unsigned long)pending.count];
            });
        }
    });
}
- (AudioItem *)readItem:(NSURL *)url {
    AudioItem *i=[AudioItem new]; i.url=url; i.status=@"已读取";
    NSTask *t=[NSTask new]; t.executableURL=[NSURL fileURLWithPath:self.ffmpegPath ?: @"/usr/bin/ffmpeg"]; t.arguments=@[@"-hide_banner",@"-i",url.path,@"-f",@"ffmetadata",@"-"]; NSPipe *pipe=[NSPipe pipe]; t.standardOutput=pipe; t.standardError=[NSFileHandle fileHandleWithNullDevice]; @try { [t launch]; NSData *d=[[pipe fileHandleForReading] readDataToEndOfFile]; [t waitUntilExit]; NSString *s=[[NSString alloc] initWithData:d encoding:NSUTF8StringEncoding] ?: @"";
        NSDictionary *map=@{@"title":@"title",@"artist":@"artist",@"albumArtist":@"album_artist",@"album":@"album",@"year":@"date",@"track":@"track",@"disc":@"disc",@"genre":@"genre",@"composer":@"composer",@"key":@"initial_key",@"chords":@"chord_progression",@"bpm":@"bpm",@"lyrics":@"lyrics",@"comment":@"comment"};
    NSMutableDictionary *tagValues=[NSMutableDictionary dictionary];
        for (NSString *line in [s componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet]) { if ([line hasPrefix:@";"] || [line hasPrefix:@"["]) continue; NSRange eq=[line rangeOfString:@"="]; if (eq.location==NSNotFound) continue; NSString *key=[[line substringToIndex:eq.location] lowercaseString]; NSString *value=[line substringFromIndex:eq.location+1]; value=[value stringByReplacingOccurrencesOfString:@"\\n" withString:@"\n"]; value=[value stringByReplacingOccurrencesOfString:@"\\=" withString:@"="]; value=[value stringByReplacingOccurrencesOfString:@"\\;" withString:@";"]; value=[value stringByReplacingOccurrencesOfString:@"\\#" withString:@"#"]; value=[value stringByReplacingOccurrencesOfString:@"\\\\" withString:@"\\"]; tagValues[key]=value; }
        for (NSString *key in map) [i setValue:tagValues[[map[key] lowercaseString]] ?: @"" forKey:key];
    } @catch (__unused NSException *e) {}
    NSString *cover=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".jpg"]]; NSTask *c=[NSTask new]; c.executableURL=[NSURL fileURLWithPath:self.ffmpegPath ?: @"/usr/bin/ffmpeg"]; c.arguments=@[@"-y",@"-i",url.path,@"-an",@"-frames:v",@"1",cover]; c.standardOutput=[NSFileHandle fileHandleWithNullDevice]; c.standardError=[NSFileHandle fileHandleWithNullDevice]; @try { [c launch]; [c waitUntilExit]; i.cover=[[NSImage alloc] initWithContentsOfFile:cover]; if (i.cover) i.coverData=[NSData dataWithContentsOfFile:cover]; [[NSFileManager defaultManager] removeItemAtPath:cover error:nil]; } @catch (__unused NSException *e) {}
    if (!i.cover && [url.pathExtension.lowercaseString isEqualToString:@"wav"]) { NSData *wavCover=[self extractWAVCoverAtPath:url.path]; if (wavCover) { i.coverData=wavCover; i.cover=[[NSImage alloc] initWithData:wavCover]; } }
    if (i.title.length==0) i.title=url.lastPathComponent.stringByDeletingPathExtension;
    return i;
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)t { return _items.count; }
- (id)tableView:(NSTableView *)t objectValueForTableColumn:(NSTableColumn *)c row:(NSInteger)r { AudioItem *i=_items[r]; if ([c.identifier isEqual:@"format"]) return i.url.pathExtension.uppercaseString; return [i valueForKey:c.identifier] ?: @""; }
- (void)tableViewSelectionDidChange:(NSNotification *)n {
    [self refreshEditorFromSelection];
}
- (void)refreshEditorFromSelection {
    NSIndexSet *rows=_table.selectedRowIndexes;
    if (rows.count==0 && _items.count>0) { [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO]; rows=_table.selectedRowIndexes; }
    AudioItem *i=rows.count ? _items[rows.firstIndex] : (_items.count ? _items.firstObject : nil);
    BOOL hasAudio=(i!=nil);
    for (NSString *key in _fields) {
        NSTextField *f=_fields[key];
        f.enabled=YES; f.editable=YES; f.selectable=YES; f.bezeled=YES; f.drawsBackground=YES;
        f.stringValue=i ? ([i valueForKey:key] ?: @"") : @"";
        if (!hasAudio) f.placeholderString=@"先添加并选择歌曲";
    }
    _newCover=nil; _removeCover=NO; _coverView.image=i.cover;
}
- (void)chooseCover:(id)sender { NSOpenPanel *p=[NSOpenPanel openPanel]; p.allowedFileTypes=@[@"jpg",@"jpeg",@"png",@"webp"]; p.allowsMultipleSelection=NO; if ([p runModal]==NSModalResponseOK) { _newCover=[NSData dataWithContentsOfURL:p.URL]; _removeCover=NO; _coverView.image=[[NSImage alloc] initWithData:_newCover]; } }
- (void)removeCover:(id)sender { _newCover=nil; _removeCover=YES; _coverView.image=nil; }
- (void)clearList:(id)sender { [_items removeAllObjects]; [_table reloadData]; [self updateTableDocumentSize]; [self tableViewSelectionDidChange:nil]; _status.stringValue=@"列表已清空。"; }
- (void)saveChanges:(id)sender {
    if (_isSaving) return;
    NSIndexSet *rows=_table.selectedRowIndexes;
    if (!rows.count && _items.count) { [_table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO]; rows=_table.selectedRowIndexes; }
    if (!rows.count) { _status.stringValue=@"请先添加歌曲，再编辑并保存。"; NSBeep(); return; }
    NSArray *keys=@[@"title",@"artist",@"albumArtist",@"album",@"year",@"track",@"disc",@"genre",@"composer",@"key",@"chords",@"bpm",@"lyrics",@"comment"];
    NSMutableDictionary *values=[NSMutableDictionary dictionary]; for (NSString *key in keys) values[key]=_fields[key].stringValue ?: @"";
    NSMutableArray<AudioItem *> *targets=[NSMutableArray array]; for (NSUInteger row=rows.firstIndex; row<rows.lastIndex+1; row=[rows indexGreaterThanIndex:row]) [targets addObject:_items[row]];
    NSDictionary *valueSnapshot=[values copy]; NSData *coverSnapshot=[_newCover copy]; BOOL removeCoverSnapshot=_removeCover;
    _isSaving=YES; _saveButton.enabled=NO; _status.stringValue=[NSString stringWithFormat:@"正在保存 %lu 首歌曲，请稍候…",(unsigned long)targets.count];
    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED,0), ^{
        NSMutableArray<NSString *> *errors=[NSMutableArray array]; NSMutableArray<AudioItem *> *saved=[NSMutableArray array];
        for (AudioItem *item in targets) { NSError *writeError=nil; NSData *coverForItem=coverSnapshot ?: (removeCoverSnapshot ? nil : item.coverData); if (![self writeItem:item keys:keys values:valueSnapshot coverData:coverForItem removeCover:removeCoverSnapshot error:&writeError]) [errors addObject:[NSString stringWithFormat:@"%@：%@",item.url.lastPathComponent,writeError.localizedDescription ?: @"格式不支持或文件写入失败"]]; else [saved addObject:item]; }
        dispatch_async(dispatch_get_main_queue(), ^{
            for (AudioItem *item in saved) { for (NSString *key in keys) [item setValue:valueSnapshot[key] forKey:key]; if (coverSnapshot) { item.coverData=coverSnapshot; item.cover=[[NSImage alloc] initWithData:coverSnapshot]; } if (removeCoverSnapshot) { item.cover=nil; item.coverData=nil; } item.status=@"已保存"; }
            [_table reloadData]; [self updateTableDocumentSize]; _isSaving=NO; _saveButton.enabled=YES; _newCover=nil; _removeCover=NO;
            if (errors.count) { _status.stringValue=[NSString stringWithFormat:@"部分保存失败：%@",[errors componentsJoinedByString:@"；"]]; NSAlert *alert=[NSAlert new]; alert.messageText=@"保存失败"; alert.informativeText=_status.stringValue; [alert addButtonWithTitle:@"好"]; [alert runModal]; }
            else { _status.stringValue=@"已修改成功"; NSAlert *alert=[NSAlert new]; alert.messageText=@"已修改成功"; alert.informativeText=@""; [alert addButtonWithTitle:@"好"]; [alert runModal]; }
        });
    });
}
- (BOOL)writeItem:(AudioItem *)item keys:(NSArray<NSString *> *)keys values:(NSDictionary<NSString *,NSString *> *)values coverData:(NSData *)coverData removeCover:(BOOL)removeCover error:(NSError **)error {
    NSFileManager *fm=[NSFileManager defaultManager];
    NSString *candidatePath=[item.url.path copy];
    NSString *originalPath=[candidatePath hasSuffix:@".tag-editor-old"] ? [candidatePath substringToIndex:candidatePath.length-@".tag-editor-old".length] : candidatePath;
    NSString *legacyStaging=[originalPath stringByAppendingString:@".tag-editor-old"];
    if (![fm fileExistsAtPath:originalPath] && [fm fileExistsAtPath:legacyStaging]) {
        NSError *recoveryError=nil;
        if (![fm moveItemAtPath:legacyStaging toPath:originalPath error:&recoveryError]) { if (error) *error=recoveryError; return NO; }
    }
    item.url=[NSURL fileURLWithPath:originalPath];
    if (![fm fileExistsAtPath:originalPath]) { if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:3 userInfo:@{NSLocalizedDescriptionKey:@"找不到原音频文件；已尝试恢复旧版保存留下的临时文件。"}]; return NO; }
    NSString *ext=originalPath.pathExtension.lowercaseString;
    if ([ext isEqual:@"aac"]) { if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:1 userInfo:@{NSLocalizedDescriptionKey:@"AAC 裸流没有通用的标签容器，无法安全写入标签或封面。"}]; return NO; }
    NSString *newTitle=[values[@"title"] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet] ?: @"";
    NSString *oldTitle=item.title ?: @"";
    NSString *targetPath=originalPath;
    if (newTitle.length && ![newTitle isEqualToString:oldTitle]) {
        NSString *safeTitle=[newTitle stringByReplacingOccurrencesOfString:@"/" withString:@"-"];
        safeTitle=[safeTitle stringByReplacingOccurrencesOfString:@":" withString:@"-"];
        safeTitle=[safeTitle stringByReplacingOccurrencesOfString:@"\\" withString:@"-"];
        while ([safeTitle hasSuffix:@"."] || [safeTitle hasSuffix:@" "]) safeTitle=[safeTitle substringToIndex:safeTitle.length-1];
        if (safeTitle.length) {
            NSString *directory=originalPath.stringByDeletingLastPathComponent;
            targetPath=[[directory stringByAppendingPathComponent:safeTitle] stringByAppendingPathExtension:ext];
            if ([originalPath caseInsensitiveCompare:targetPath]!=NSOrderedSame && [fm fileExistsAtPath:targetPath]) {
                if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:4 userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"目标文件名已存在：%@。为避免覆盖，该歌曲未保存。",targetPath.lastPathComponent]}];
                return NO;
            }
        }
    }
    BOOL isWAV=[ext isEqual:@"wav"];
    NSString *format=([ext isEqual:@"aiff"] || [ext isEqual:@"aif"]) ? @"aiff" : ([ext isEqual:@"m4a"] ? @"ipod" : ext);
    NSString *temp=[originalPath.stringByDeletingPathExtension stringByAppendingFormat:@".tag-editor-%@.%@",NSUUID.UUID.UUIDString,ext];
    NSString *backup=[originalPath stringByAppendingString:@".backup"];
    NSMutableArray *args=[NSMutableArray arrayWithObjects:@"-y",@"-hide_banner",@"-v",@"error",@"-i",originalPath,nil];
    NSString *coverPath=nil; BOOL attach=(coverData != nil && !isWAV);
    if (attach) { coverPath=[NSTemporaryDirectory() stringByAppendingPathComponent:[NSUUID.UUID.UUIDString stringByAppendingString:@".jpg"]]; if (![coverData writeToFile:coverPath atomically:YES]) return NO; [args addObjectsFromArray:@[@"-i",coverPath]]; }
    if (removeCover || (isWAV && coverData)) [args addObjectsFromArray:@[@"-map",@"0:a?",@"-map",@"0:s?"]];
    else if (attach) [args addObjectsFromArray:@[@"-map",@"0:a?",@"-map",@"0:s?",@"-map",@"1:v:0"]];
    else [args addObjectsFromArray:@[@"-map",@"0"]];
    [args addObjectsFromArray:@[@"-map_metadata",@"0",@"-c",@"copy"]];
    if (attach) [args addObjectsFromArray:@[@"-c:v",@"mjpeg",@"-disposition:v:0",@"attached_pic"]];
    NSDictionary *metadata=@{@"title":@"title",@"artist":@"artist",@"albumArtist":@"album_artist",@"album":@"album",@"year":@"date",@"track":@"track",@"disc":@"disc",@"genre":@"genre",@"composer":@"composer",@"key":@"initial_key",@"chords":@"chord_progression",@"bpm":@"bpm",@"lyrics":@"lyrics",@"comment":@"comment"};
    for (NSString *key in keys) [args addObjectsFromArray:@[@"-metadata",[NSString stringWithFormat:@"%@=%@",metadata[key],values[key] ?: @""]]];
    [args addObjectsFromArray:@[@"-f",format,temp]];
    NSTask *task=[NSTask new]; task.executableURL=[NSURL fileURLWithPath:self.ffmpegPath ?: @"/usr/bin/ffmpeg"]; task.arguments=args; task.standardOutput=[NSFileHandle fileHandleWithNullDevice]; NSPipe *errorPipe=[NSPipe pipe]; task.standardError=errorPipe; BOOL ok=NO; NSString *ffmpegError=@"";
    @try { [task launch]; [errorPipe.fileHandleForWriting closeFile]; NSData *stderrData=[[errorPipe fileHandleForReading] readDataToEndOfFile]; [task waitUntilExit]; ok=(task.terminationStatus==0); ffmpegError=[[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding] ?: @""; } @catch (NSException *exception) { ffmpegError=exception.reason ?: @"无法启动 FFmpeg"; ok=NO; }
    if (coverPath) [[NSFileManager defaultManager] removeItemAtPath:coverPath error:nil];
    if (!ok || ![fm fileExistsAtPath:temp]) { [fm removeItemAtPath:temp error:nil]; if (error) *error=[NSError errorWithDomain:@"MusicTagEditor" code:2 userInfo:@{NSLocalizedDescriptionKey:(ffmpegError.length ? ffmpegError : @"音频格式不支持写入这些信息。")}]; return NO; }
    if (isWAV && (coverData || removeCover) && ![self rewriteWAVAtPath:temp coverData:(removeCover ? nil : coverData) error:error]) { [fm removeItemAtPath:temp error:nil]; return NO; }
    NSError *e=nil;
    NSString *staging=[originalPath stringByAppendingString:@".tag-editor-old"]; [fm removeItemAtPath:staging error:nil];
    if (![fm moveItemAtPath:originalPath toPath:staging error:&e]) { [fm removeItemAtPath:temp error:nil]; if (error) *error=e; return NO; }
    if (![fm moveItemAtPath:temp toPath:targetPath error:&e]) { [fm moveItemAtPath:staging toPath:originalPath error:nil]; if (error) *error=e; return NO; }
    [fm removeItemAtPath:staging error:nil];
    // Remove sidecar backups left by older app versions after the replacement succeeds.
    [fm removeItemAtPath:backup error:nil];
    if (![targetPath isEqualToString:originalPath]) [fm removeItemAtPath:[targetPath stringByAppendingString:@".backup"] error:nil];
    item.url=[NSURL fileURLWithPath:targetPath];
    return YES;
}
@end

int main(int argc, const char *argv[]) {
    @autoreleasepool { NSApplication *app=[NSApplication sharedApplication]; app.activationPolicy=NSApplicationActivationPolicyRegular; AppDelegate *delegate=[AppDelegate new]; app.delegate=delegate; [app run]; }
    return 0;
}
