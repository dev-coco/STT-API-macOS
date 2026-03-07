# MultiSense API

MultiSense API 是专为 macOS 设计的本地音频与图像识别 API 服务，识别速度极快。

所有处理均在本地完成，无需 Key，无需联网，隐私安全。

[[简体中文]](README.zh-CN.md) [[English]](README.md)

---

## 快速开始

1. **加载模型**：在应用界面点击 `加载模型`，软件将会自动下载语音转文字模型。如果无需使用语音转文本功能，可以跳过此步骤。
2. **启动服务**：设置监听端口并点击 `启动 API 服务`。
3. **状态检查**：通过访问根路径确认各引擎就绪情况。

基础 URL: `http://127.0.0.1:1643`

![](Screenshot.png)

---

## 功能就绪检测

在调用具体接口前，建议通过此接口检测特定功能是否已启用或模型是否加载完成。

### `GET` **/**
检查 API 服务存活状态及内部组件初始化情况。

#### 调用示例 (JavaScript)
```JavaScript
const json = await fetch('http://localhost:1643').then(response => response.json())
console.log(json)
```

#### 响应属性
* **status** `string`
    服务运行状态，正常时返回 `"success"`。
* **transcribe** `boolean`
    **语音转录就绪状态**。若为 `false`，表示 ASR 模型尚未下载或正在加载中，此时调用 `/transcribe` 将触发自动初始化。
* **ocr** `boolean`
    **视觉引擎就绪状态**。基于 macOS 系统框架，通常始终为 `true`。
* **classify** `boolean`
    **物体分类引擎就绪状态**。基于 macOS 系统框架，通常始终为 `true`。

> **响应示例**
> ```json
> {
>   "status": "success",
>   "transcribe": true,
>   "ocr": true
>   "classify": true
> }
> ```

---

## 接口参考

### 语音转文字
`POST` **/transcribe**

将音频或视频流转换为文本。

支持语言：英语、西班牙语、法语、俄语、德语、意大利语、波兰语、乌克兰语、罗马尼亚语、荷兰语、匈牙利语、希腊语、瑞典语、捷克语、保加利亚语、葡萄牙语、斯洛伐克语、克罗地亚语、丹麦语、芬兰语、立陶宛语、斯洛文尼亚语、拉脱维亚语、爱沙尼亚语、马耳他语。

#### 请求参数 (Multipart/Form-Data)
| 参数 | 类型 | 状态 | 描述 |
| :--- | :--- | :--- | :--- |
| `audio` | `file` | <kbd>必填</kbd> | 待转录的音频二进制流。 |

#### 调用示例 (JavaScript)
```JavaScript
const blob = await fetch('https://example.com/demo.mp3').then(response => response.blob())

const formData = new FormData()
formData.append('audio', blob)
const json = await fetch('http://localhost:1643/transcribe', {
  method: 'POST',
  body: formData
}).then(response => response.json())

console.log(json.text)

```

> **响应示例**
> ```json
> {
>   "text": "Text content identified from audio."
> }
> ```

---

### 图片识别文本
`POST` **/ocr**

从图像中提取多语言文本。

<details>
<summary>支持语言</summary>

| 语言代码 | 语言 |
|:---:|:---:|
| en-US | 英语（美国） |
| fr-FR | 法语（法国） |
| it-IT | 意大利语 |
| de-DE | 德语 |
| es-ES | 西班牙语 |
| pt-BR | 葡萄牙语（巴西） |
| zh-Hans | 中文（简体） |
| zh-Hant | 中文（繁体） |
| yue-Hans | 粤语（简体） |
| yue-Hant | 粤语（繁体） |
| ko-KR | 韩语 |
| ja-JP | 日语 |
| ru-RU | 俄语 |
| uk-UA | 乌克兰语 |
| th-TH | 泰语 |
| vi-VT | 越南语 |
| ar-SA | 阿拉伯语（标准阿拉伯语） |
| ars-SA | 阿拉伯语（纳吉迪方言，沙特地区） |

</details>


#### 请求参数 (Multipart/Form-Data)
| 参数 | 类型 | 状态 | 描述 |
| :--- | :--- | :--- | :--- |
| `image` | `file` | <kbd>必填</kbd> | 需要处理的图像文件。 |
| `language` | `string` | <kbd>可选</kbd> | 语言代码（如 `zh-Hans,en-US`），默认为中英双语。 |
| `lineBreak` | `boolean` | <kbd>可选</kbd> | 是否保留识别出的换行符。默认为 `true`。 |

#### 调用示例 (JavaScript)
```JavaScript
const blob = await fetch('https://example.com/demo.jpg').then(response => response.blob())

const formData = new FormData()
formData.append('image', blob)
formData.append('language', 'es-ES')
formData.append('lineBreak', false)
const json = await fetch('http://localhost:1643/ocr', {
  method: 'POST',
  body: formData
}).then(response => response.json())

console.log(json.text)

```

> **响应示例**
> ```json
> {
>   "text": "Text content identified from image."
> }
> ```

---

### 图像分类
`POST` **/classify**

识别图像中的物体、场景并返回置信度评分。

#### 请求参数 (Multipart/Form-Data)
| 参数 | 类型 | 状态 | 描述 |
| :--- | :--- | :--- | :--- |
| `image` | `file` | <kbd>必填</kbd> | 需识别的物体图像。 |

#### 调用示例 (JavaScript)
```JavaScript
const blob = await fetch('https://example.com/demo.jpg').then(response => response.blob())

const formData = new FormData()
formData.append('image', blob)
const json = await fetch('http://localhost:1643/classify', {
  method: 'POST',
  body: formData
}).then(response => response.json())

console.log(json)

```

<details>
<summary>标签中文映射</summary>

```JavaScript
const list = {"abacus":"算盘","accordion":"手风琴","acorn":"橡子","acrobat":"杂技演员","adult":"成年人","adult_cat":"成年猫","agriculture":"农业","aircraft":"航空器","airplane":"飞机","airport":"机场","airshow":"航空表演","alley":"小巷","alligator_crocodile":"鳄鱼","almond":"杏仁","ambulance":"救护车","amusement_park":"游乐园","anchovy":"凤尾鱼","angelfish":"神仙鱼","animal":"动物","ant":"蚂蚁","antipasti":"意式前菜","anvil":"铁砧","apartment":"公寓","apple":"苹果","appliance":"家用电器","apricot":"杏","apron":"围裙","aquarium":"水族馆","arachnid":"蛛形纲动物","arch":"拱门","archery":"射箭","arena":"竞技场","armchair":"扶手椅","art":"艺术","arthropods":"节肢动物","artichoke":"朝鲜蓟","arugula":"芝麻菜","asparagus":"芦笋","athletics":"田径运动","atm":"取款机","atv":"全地形车","auditorium":"礼堂","aurora":"极光","australian_shepherd":"澳大利亚牧羊犬","automobile":"汽车","avocado":"牛油果","axe":"斧头","baby":"婴儿","backgammon":"西洋双陆棋","backhoe":"反铲装载机","backpack":"背包","bacon":"培根","badminton":"羽毛球","bag":"包","bagel":"贝果","baked_goods":"烘焙食品","baklava":"果仁蜜饼","balcony":"阳台","ball":"球","ballet":"芭蕾舞","ballet_dancer":"芭蕾舞演员","ballgames":"球类运动","balloon":"气球","balloon_hotair":"热气球","banana":"香蕉","banner":"横幅","bar":"酒吧","barbell":"杠铃","barge":"驳船","barn":"谷仓","barnacle":"藤壶","barracuda":"梭鱼","barrel":"桶","baseball":"棒球","baseball_bat":"棒球棒","baseball_hat":"棒球帽","basenji":"巴仙吉犬","basket_container":"篮子","basketball":"篮球","basset":"巴吉度猎犬","bath":"洗澡","bathrobe":"浴袍","bathroom":"浴室","bathroom_faucet":"浴室水龙头","bathroom_room":"卫生间","beach":"海滩","beagle":"比格犬","bean":"豆子","beanie":"针织帽","bear":"熊","bed":"床","bedding":"床上用品","bedroom":"卧室","bee":"蜜蜂","beef":"牛肉","beehive":"蜂巢","beekeeping":"养蜂","beer":"啤酒","beet":"甜菜","begonia":"秋海棠","bell":"铃","bell_pepper":"甜椒","belltower":"钟楼","bellydance":"肚皮舞","bench":"长椅","bernese_mountain":"伯恩山犬","berry":"浆果","bib":"围嘴","bichon":"比熊犬","bicycle":"自行车","billboards":"广告牌","billiards":"台球","binoculars":"望远镜","bird":"鸟","birdhouse":"鸟屋","birthday_cake":"生日蛋糕","biryani":"印度香饭","biscotti":"意大利脆饼","biscuit":"饼干","bison":"美洲野牛","blackberry":"黑莓","bleachers":"露天看台","blender":"搅拌机","blizzard":"暴风雪","blocks":"积木","blossom":"花朵","blue_sky":"蓝天","blueberry":"蓝莓","boar":"野猪","board_game":"桌游","boat":"船","boathouse":"船屋","bobcat":"山猫","bodyboard":"趴板","bongo_drum":"邦戈鼓","bonsai":"盆景","book":"书","bookshelf":"书架","boot":"靴子","bottle":"瓶子","bouquet":"花束","bowl":"碗","bowling":"保龄球","bowtie":"领结","boxing":"拳击","branch":"树枝","brass_music":"铜管音乐","bread":"面包","breakdancing":"霹雳舞","brick":"砖","brick_oven":"砖炉","bride":"新娘","bridesmaid":"伴娘","bridge":"桥","briefcase":"公文包","broccoli":"西兰花","broom":"扫帚","brownie":"布朗尼","bruschetta":"意式烤面包","bubble_tea":"珍珠奶茶","bucket":"水桶","building":"建筑","bulldog":"斗牛犬","bulldozer":"推土机","bullfighting":"斗牛","bungee":"蹦极","burrito":"墨西哥卷饼","bus":"公交车","butter":"黄油","butterfly":"蝴蝶","cabinet":"橱柜","cableway":"缆车","cactus":"仙人掌","cage":"笼子","cake":"蛋糕","cake_regular":"普通蛋糕","cakestand":"蛋糕架","calculator":"计算器","calendar":"日历","caliper":"游标卡尺","camel":"骆驼","camera":"相机","camping":"野营","candle":"蜡烛","candlestick":"烛台","candy":"糖果","candy_cane":"拐杖糖","candy_other":"其他糖果","canine":"犬科动物","canoe":"独木舟","cantaloupe":"哈密瓜","canyon":"峡谷","caprese":"卡普雷塞沙拉","car":"汽车","car_seat":"儿童安全座椅","caramel":"焦糖","cardboard_box":"纸箱","carnation":"康乃馨","carnival":"嘉年华","carousel":"旋转木马","carrot":"胡萝卜","cart":"手推车","carton":"纸盒","cashew":"腰果","casino":"赌场","casserole":"烤菜","cassette":"卡带","castle":"城堡","cat":"猫","caterpillar":"毛毛虫","cauliflower":"花椰菜","cave":"洞穴","cd":"光盘","celebration":"庆祝活动","celery":"芹菜","celestial_body":"天体","celestial_body_other":"其他天体","cellar":"地窖","cello":"大提琴","centipede":"蜈蚣","cephalopod":"头足类动物","cereal":"谷类食品","ceremony":"仪式","cetacean":"鲸类","chainsaw":"链锯","chair":"椅子","chair_other":"其他椅子","chairlift":"缆椅","chaise":"躺椅","chalkboard":"黑板","chameleon":"变色龙","chandelier":"吊灯","chart":"图表","checkbook":"支票簿","cheerleading":"啦啦队","cheese":"奶酪","cheesecake":"芝士蛋糕","cheetah":"猎豹","cherry":"樱桃","chess":"国际象棋","chestnut":"栗子","chewing_gum":"口香糖","chihuahua":"吉娃娃","child":"儿童","chimney":"烟囱","chinchilla":"龙猫","chives":"韭菜","chocolate":"巧克力","chocolate_chip":"巧克力碎片","chopsticks":"筷子","christmas_decoration":"圣诞装饰","christmas_tree":"圣诞树","chrysanthemum":"菊花","cigar":"雪茄","cigarette":"香烟","cilantro":"香菜","circuit_board":"电路板","circus":"马戏团","citrus_fruit":"柑橘类水果","cityscape":"城市景观","clam":"蛤蜊","clarinet":"单簧管","classroom":"教室","cliff":"悬崖","cloak":"斗篷","clock":"钟","clock_tower":"钟楼","closet":"衣柜","clothesline":"晾衣绳","clothespin":"衣夹","clothing":"衣物","cloudy":"多云","clover":"苜蓿","clown":"小丑","clownfish":"小丑鱼","cockatoo":"鸚鵡","cocktail":"鸡尾酒","coconut":"椰子","coffee":"咖啡","coffee_bean":"咖啡豆","coin":"硬币","coleslaw":"卷心菜沙拉","collie":"柯利犬","compass":"指南针","computer":"电脑","computer_keyboard":"电脑键盘","computer_monitor":"电脑显示器","computer_mouse":"电脑鼠标","computer_tower":"电脑主机","concert":"音乐会","conch":"海螺","condiment":"调味品","conference":"会议","consumer_electronics":"消费电子产品","container":"容器","convertible":"敞篷车","conveyance":"交通工具","cookie":"饼干","cookware":"厨具","coral_reef":"珊瑚礁","cord":"绳索 / 电线","corgi":"柯基犬","corkscrew":"开瓶器","corn":"玉米","cornflower":"矢车菊","cosmetic_tool":"化妆工具","costume":"服装 / 戏装","cougar":"美洲狮","coupon":"优惠券","cow":"奶牛","cowboy_hat":"牛仔帽","coyote_wolf":"郊狼","crab":"螃蟹","cranberry":"蔓越莓","crane_construction":"起重机","crate":"木箱","credit_card":"信用卡","creek":"小溪","crepe":"可丽饼","crib":"婴儿床","cricket_sport":"板球","croissant":"羊角面包","crosswalk":"斑马线","crowd":"人群","cruise_ship":"邮轮","crutch":"拐杖","cubicle":"办公隔间","cucumber":"黄瓜","cup":"杯子","cupcake":"纸杯蛋糕","currency":"货币","curry":"咖喱","curtain":"窗帘","cutting_board":"砧板","cycling":"骑行","dachshund":"腊肠犬","daffodil":"水仙花","dahlia":"大丽花","daikon":"白萝卜","daisy":"雏菊","dalmatian":"大麦町犬","dam":"大坝","dancing":"舞蹈","dandelion":"蒲公英","dartboard":"飞镖靶","dashboard":"仪表盘","daytime":"白天","decanter":"酒瓶 / 醒酒器","deck":"甲板","decoration":"装饰","decorative_plant":"观赏植物","deejay":"DJ","deer":"鹿","desert":"沙漠","desk":"书桌","dessert":"甜点","diagram":"图示","dial":"拨号盘","diaper":"尿布","dice":"骰子","dill":"莳萝","dining_room":"餐厅","dinosaur":"恐龙","diorama":"立体模型","dirt_road":"土路","disco_ball":"迪斯科球","dishwasher":"洗碗机","diskette":"软盘","diving":"潜水","doberman":"杜宾犬","dock":"码头","document":"文件","dog":"狗","doll":"洋娃娃","dolphin":"海豚","dome":"圆顶","domicile":"住宅","domino":"多米诺骨牌","donkey":"驴","donut":"甜甜圈","door":"门","dove":"鸽子","dragon_parade":"龙舞游行","dragonfly":"蜻蜓","dressage":"盛装舞步","drink":"饮料","drinking_glass":"饮水杯","driveway":"私家车道","drone_machine":"无人机","drum":"鼓","dumbbell":"哑铃","dumpling":"饺子","durian":"榴莲","eagle":"老鹰","earmuffs":"耳罩","easel":"画架","easter_egg":"复活节彩蛋","edamame":"毛豆","egg":"鸡蛋","eggplant":"茄子","electric_fan":"电风扇","elephant":"大象","elevator":"电梯","elk":"麋鹿","embers":"余烬","engine_vehicle":"发动机车辆","entertainer":"演艺人员","envelope":"信封","equestrian":"马术","escalator":"扶梯","eucalyptus_tree":"尤加利树","evergreen":"常绿树","extinguisher":"灭火器","eyeglasses":"眼镜","fairground":"游乐场","falafel":"鹰嘴豆丸","farm":"农场","fedora":"菲多拉帽","feline":"猫科动物","fence":"篱笆","fencing_sport":"击剑","ferns":"蕨类植物","ferret":"雪貂","ferris_wheel":"摩天轮","fig":"无花果","figurine":"小雕像","fire":"火","firecracker":"鞭炮","fireplace":"壁炉","firetruck":"消防车","fireworks":"烟花","fish":"鱼","fishbowl":"鱼缸","fishing":"钓鱼","fishtank":"水族箱","flag":"旗帜","flagpole":"旗杆","flame":"火焰","flamingo":"火烈鸟","flan":"焦糖布丁","flashlight":"手电筒","flipchart":"翻页图表","flipper":"蛙鞋","flower":"花","flower_arrangement":"花卉布置","flute":"长笛","folding_chair":"折叠椅","foliage":"叶子","fondue":"奶酪火锅","food":"食物","foosball":"桌上足球","football":"足球","footwear":"鞋类","forest":"森林","fork":"叉子","forklift":"叉车","formula_one_car":"一级方程式赛车","fountain":"喷泉","fox":"狐狸","frame":"框架","fried_chicken":"炸鸡","fried_egg":"煎蛋","fries":"薯条","frisbee":"飞盘","frog":"青蛙","frozen":"冰冻的","frozen_dessert":"冷冻甜点","fruit":"水果","fruitcake":"水果蛋糕","furniture":"家具","gamepad":"游戏手柄","games":"游戏","garage":"车库","garden":"花园","gargoyle":"怪兽雕像","garlic":"大蒜","gas_mask":"防毒面具","gastropod":"腹足类动物","gazebo":"凉亭","gears":"齿轮","gecko":"壁虎","gerbil":"沙鼠","german_shepherd":"德国牧羊犬","geyser":"间歇泉","gift":"礼物","gift_card":"礼品卡","gingerbread":"姜饼","giraffe":"长颈鹿","glacier":"冰川","glove":"手套","glove_other":"其他手套","go_kart":"卡丁车","goat":"山羊","goggles":"护目镜","goldfish":"金鱼","golf":"高尔夫","golf_ball":"高尔夫球","golf_club":"高尔夫球杆","golf_course":"高尔夫球场","gown":"礼服","graduation":"毕业","graffiti":"涂鸦","grain":"谷物","grand_prix":"大奖赛","grape":"葡萄","grapefruit":"葡萄柚","grass":"草","grater":"刨丝器","grave":"坟墓","green_beans":"四季豆","greenhouse":"温室","greyhound":"灰狗","grill":"烧烤架","grilled_chicken":"烤鸡","groom":"新郎","guacamole":"牛油果酱","guava":"番石榴","guitar":"吉他","gull":"海鸥","guppy":"孔雀鱼","gymnastics":"体操","gyoza":"饺子","habanero":"哈瓦那辣椒","ham":"火腿","hamburger":"汉堡","hammer":"锤子","hammock":"吊床","hamster":"仓鼠","handwriting":"手写字","hangar":"飞机库","hangglider":"滑翔机","harbour":"港口","hardhat":"安全帽","harp":"竖琴","hat":"帽子","haze":"雾霾","headgear":"头盔/头饰","headphones":"头戴式耳机","health_club":"健身房","hedgehog":"刺猬","helicopter":"直升机","helmet":"头盔","henna":"纹身粉/海娜","herb":"草本植物","heron":"鹭","high_chair":"儿童高脚椅","high_heel":"高跟鞋","hiking":"徒步","hill":"小山","hippopotamus":"河马","hockey":"曲棍球","holly":"冬青","honey":"蜂蜜","honeydew":"蜜瓜","hoodie":"卫衣","hookah":"水烟","horse":"马","horseshoe":"马蹄铁","hospital":"医院","hotdog":"热狗","hound":"猎犬","hourglass":"沙漏","house_single":"独立房屋","houseboat":"船屋","housewares":"家居用品","hula":"呼啦圈舞","hummingbird":"蜂鸟","hummus":"鹰嘴豆泥","hunting":"狩猎","hurdle":"跨栏","husky":"哈士奇","hydrant":"消防栓","hyena":"鬣狗","ice":"冰","ice_cream":"冰淇淋","ice_skates":"冰鞋","ice_skating":"滑冰","iceberg":"冰山","igloo":"雪屋","iguana":"鬣蜥","illustrations":"插图","insect":"昆虫","interior_room":"室内房间","interior_shop":"室内商店","irish_wolfhound":"爱尔兰猎狼犬","iron_clothing":"熨衣服","island":"岛屿","ivy":"常春藤","jack_o_lantern":"南瓜灯","jack_russell_terrier":"杰克罗素梗","jacket":"夹克","jacuzzi":"按摩浴缸","jalapeno":"墨西哥辣椒","jar":"罐子","jeans":"牛仔裤","jeep":"吉普车","jello":"果冻","jelly":"果酱","jellyfish":"水母","jetski":"水上摩托","jewelry":"珠宝","jigsaw":"拼图","jockey_horse":"赛马骑师","joystick":"操纵杆","jug":"水壶","juggling":"杂耍","juice":"果汁","juicer":"榨汁机","jungle":"丛林","kangaroo":"袋鼠","karaoke":"卡拉OK","kayak":"皮划艇","kebab":"烤肉串","keg":"啤酒桶","kettle":"水壶","keypad":"按键板","kickboxing":"踢拳","kilt":"格子短裙","kimono":"和服","kitchen":"厨房","kitchen_countertop":"厨房台面","kitchen_faucet":"厨房水龙头","kitchen_oven":"厨房烤箱","kitchen_room":"厨房房间","kitchen_sink":"厨房水槽","kite":"风筝","kiteboarding":"风筝冲浪","kitten":"小猫","kiwi":"猕猴桃","knife":"刀","koala":"考拉","kohlrabi":"芥蓝","koi":"锦鲤","lab_coat":"实验服","ladle":"汤勺","ladybug":"瓢虫","lake":"湖","lamp":"灯","lamppost":"路灯","land":"土地","lantern":"灯笼","laptop":"笔记本电脑","laundry_machine":"洗衣机","lava":"熔岩","leash":"牵引绳","leek":"韭葱","lemon":"柠檬","lemongrass":"香茅","lemur":"狐猴","leopard":"豹","leotard":"紧身舞衣","lettuce":"生菜","library":"图书馆","license_plate":"车牌","lifejacket":"救生衣","lifesaver":"救生圈","light":"光","light_bulb":"灯泡","lighter":"打火机","lighthouse":"灯塔","lightning":"闪电","lily":"百合","lime":"青柠","limousine":"豪华轿车","lion":"狮子","lionfish":"狮子鱼","liquid":"液体","liquor":"酒精饮料","living_room":"客厅","lizard":"蜥蜴","llama":"羊驼","loafer":"乐福鞋","lobster":"龙虾","lollipop":"棒棒糖","luggage":"行李","lychee":"荔枝","lynx":"山猫","macadamia":"夏威夷果","machine":"机器","mackerel":"鲭鱼","magazine":"杂志","mailbox":"邮箱","malamute":"阿拉斯加雪橇犬","malinois":"比利时牧羊犬","mallet":"木槌","mammal":"哺乳动物","mandarine":"橘子","mango":"芒果","mangosteen":"山竹","mangrove":"红树林","manhole":"人孔","map":"地图","maple_tree":"枫树","margarita":"玛格丽塔鸡尾酒","marigold":"金盏花","marshmallow":"棉花糖","marsupial":"有袋类动物","martial_arts":"武术","martini":"马提尼鸡尾酒","mask":"面具","mast":"桅杆","mastiff":"大型犬","matches":"火柴","material":"材料","matzo":"无酵饼","measuring_tape":"卷尺","meat":"肉类","meatball":"肉丸","medal":"奖牌","media":"媒体","medicine":"药物","megalith":"巨石","megaphone":"扩音器","melon":"哈密瓜","microphone":"麦克风","microscope":"显微镜","microwave":"微波炉","military_uniform":"军装","milkshake":"奶昔","millipede":"蜈蚣","mistletoe":"槲寄生","mitten":"连指手套","moccasin":"莫卡辛鞋","mojito":"莫吉托鸡尾酒","mollusk":"软体动物","money":"钱","monitor_lizard":"巨蜥","monorail":"单轨列车","monument":"纪念碑","moon":"月亮","moose":"驼鹿","mop":"拖把","moss":"苔藓","moth":"蛾","motocross":"越野摩托","motorcycle":"摩托车","motorhome":"房车","motorsport":"赛车运动","mountain":"山","mousetrap":"捕鼠器","mower":"割草机","muffin":"松饼","mug":"马克杯","museum":"博物馆","mushroom":"蘑菇","music":"音乐","musical_instrument":"乐器","mussel":"青口贝","mustard":"芥末","naan":"印度烤饼","nachos":"玉米片","nascar":"纳斯卡赛车","necktie":"领带","nectarine":"油桃","nest":"鸟巢","newfoundland":"纽芬兰犬","newspaper":"报纸","night_sky":"夜空","nightclub":"夜总会","nut":"坚果","oak_tree":"橡树","oar":"桨","oatmeal":"燕麦粥","obelisk":"方尖碑","ocean":"海洋","office_supplies":"办公用品","omelet":"煎蛋卷","onion":"洋葱","optical_equipment":"光学设备","oranges":"橙子","orchard":"果园","orchestra":"管弦乐队","orchid":"兰花","organ_instrument":"管风琴","origami":"折纸","ostrich":"鸵鸟","otter":"水獭","outdoor":"户外","oven":"烤箱","owl":"猫头鹰","oyster":"牡蛎","pacifier":"安抚奶嘴","paella":"西班牙海鲜饭","paintball":"彩弹射击","paintbrush":"画笔","painting":"画","palm_tree":"棕榈树","pan":"平底锅","pancake":"煎饼","panda":"熊猫","papaya":"木瓜","paper_bag":"纸袋","parachute":"降落伞","parade":"游行","parakeet":"小鹦鹉","parasailing":"拖伞运动","park":"公园","parking_lot":"停车场","parrot":"鹦鹉","passionfruit":"百香果","passport":"护照","pasta":"意大利面","pastry":"糕点","path":"小路","patio":"露台","payphone":"公用电话","pea":"豌豆","peach":"桃子","peacock":"孔雀","peanut":"花生","pear":"梨","pecan":"山核桃","pelican":"鹈鹕","pen":"笔","penguin":"企鹅","people":"人们","pepper_veggie":"胡椒（蔬菜）","pepperoni":"意大利辣香肠","peregrine":"游隼","performance":"表演","pergola":"凉棚","persimmon":"柿子","petunia":"矮牵牛","phone":"电话","piano":"钢琴","pickle":"腌菜","pie":"馅饼","pier":"码头","pierogi":"波兰饺子","pig":"猪","pigeon":"鸽子","piggybank":"存钱罐","pillow":"枕头","pineapple":"菠萝","ping_pong":"乒乓球","pipe":"管子","pistachio":"开心果","pita":"皮塔饼","pitbull":"比特犬","pizza":"披萨","plant":"植物","plate":"盘子","play_card":"扑克牌","playground":"操场","pliers":"钳子","plum":"李子","podium":"讲台","poinsettia":"圣诞红","poker":"扑克","pole":"杆","police_car":"警车","polka_dots":"圆点图案","polo":"马球","pomegranate":"石榴","pomeranian":"博美犬","poncho":"雨披","poodle":"贵宾犬","pool":"游泳池","popcorn":"爆米花","popsicle":"冰棒","porch":"门廊","porcupine":"豪猪","portal":"门户","porthole":"舷窗","pot_cooking":"烹饪锅","potato":"土豆","poultry":"家禽","power_saw":"电锯","prairie_dog":"草原犬鼠","pretzel":"椒盐卷饼","printed_page":"印刷页面","printer":"打印机","propeller":"螺旋桨","puck":"冰球","pudding":"布丁","puffer_fish":"河豚","puffin":"海鹦","pug":"哈巴狗","pulley":"滑轮","pumpkin":"南瓜","puppet":"木偶","purse":"钱包","putt":"推杆","puzzles":"拼图","pylon":"电塔","pyramid":"金字塔","pyrotechnics":"烟火表演","python":"蟒蛇","quesadilla":"墨西哥烤饼","quinoa":"藜麦","rabbit":"兔子","raccoon":"浣熊","racquet":"球拍","radish":"萝卜","rafting":"漂流","railroad":"铁路","rainbow":"彩虹","rake":"耙子","rambutan":"红毛丹","ramen":"拉面","rangoli":"彩粉地画","raptor":"猛禽","raspberry":"覆盆子","rat":"老鼠","ratchet":"棘轮","rattlesnake":"响尾蛇","raven":"渡鸦","raw_glass":"生玻璃","receipt":"收据","record":"唱片","recreation":"娱乐","red_envelope":"红包","red_wine":"红酒","refrigerator":"冰箱","reptile":"爬行动物","restaurant":"餐厅","retriever":"金毛猎犬 / 拉布拉多猎犬","rhinoceros":"犀牛","rhubarb":"大黄","rice":"米饭","rice_field":"稻田","rickshaw":"人力车","ridgeback":"里奇巴克犬","rim":"轮辋","rink":"溜冰场","risotto":"烩饭","river":"河流","road":"道路","road_other":"其他道路","road_safety_equipment":"道路安全设施","rock_climbing":"攀岩","rocket":"火箭","rocks":"岩石","rodent":"啮齿动物","rodeo":"牛仔竞技表演","roe":"鱼子","rollercoaster":"过山车","rollerskates":"滑轮鞋","rollerskating":"滑轮运动","rolling_pin":"擀面杖","roof":"屋顶","rope":"绳子","rose":"玫瑰","rosemary":"迷迭香","rotisserie":"旋转烤架","rottweiler":"罗威纳犬","roulette":"轮盘赌","rowboat":"划艇","rugby":"橄榄球","ruins":"遗迹","sack":"麻袋","saddle":"马鞍","safety_vest":"安全背心","sailboat":"帆船","saint_bernard":"圣伯纳犬","salad":"沙拉","salami":"意大利腊肠","salmon":"三文鱼","samba":"桑巴舞","samosa":"印度炸三角饺","sand":"沙子","sand_dune":"沙丘","sandal":"凉鞋","sandcastle":"沙堡","sandpiper":"沙滨鸟","sandwich":"三明治","sangria":"桑格利亚酒","santa_claus":"圣诞老人","sardine":"沙丁鱼","sari":"纱丽","satay":"沙爹","sauerkraut":"德式酸菜","sausage":"香肠","saxophone":"萨克斯","scallop":"扇贝","scarab":"甲虫","scarecrow":"稻草人","scarf":"围巾","schnauzer":"雪纳瑞犬","scissors":"剪刀","scone":"司康饼","scooter":"滑板车","scoreboard":"记分板","scorpion":"蝎子","scrambled_eggs":"炒蛋","screenshot":"截图","screwdriver":"螺丝刀","scuba":"潜水","seabass":"海鲈鱼","seafood":"海鲜","seahorse":"海马","seal":"海豹","sealion":"海狮","seashell":"贝壳","seasonings":"调味料","seat":"座位","seaweed":"海藻","seed":"种子","seesaw":"跷跷板","semi_truck":"半挂卡车","sequoia":"红杉","sesame":"芝麻","setter":"塞特犬","sewing":"缝纫","shark":"鲨鱼","shawarma":"沙威玛","shed":"小屋","sheep":"绵羊","sheepdog":"牧羊犬","shellfish":"贝类","shellfish_prepared":"熟贝类","shipyard":"造船厂","shoes":"鞋","shopping_cart":"购物车","shore":"岸边","shower":"淋浴","shrub":"灌木","sidewalk":"人行道","sign":"标志","silo":"筒仓","singer":"歌手","skateboard":"滑板","skateboarding":"滑板运动","skatepark":"滑板公园","skating":"滑冰","skeleton":"骷髅","ski_boot":"滑雪靴","ski_equipment":"滑雪设备","skiing":"滑雪","skull":"头骨","skunk":"臭鼬","sky":"天空","skydiving":"跳伞","skyscraper":"摩天大楼","sled":"雪橇","sledding":"玩雪橇","slide_toy":"滑梯玩具","smokestack":"烟囱","smoking_item":"吸烟物品","smoothie":"冰沙","snail":"蜗牛","snake":"蛇","snake_other":"其他蛇","snapdragon":"金鱼草","snapper":"鲷鱼","sneaker":"运动鞋","snorkeling":"浮潜","snow":"雪","snowball":"雪球","snowboard":"单板滑雪","snowboarding":"单板滑雪运动","snowman":"雪人","snowmobile":"雪地摩托","snowshoe":"雪鞋","soccer":"足球","sock":"袜子","soda":"苏打水","sofa":"沙发","softball":"垒球","solar_panel":"太阳能板","sombrero":"墨西哥帽","souffle":"舒芙蕾","soup":"汤","souvlaki":"希腊烤肉串","spaghetti":"意大利面","spaniel":"西班牙猎犬","spareribs":"排骨","sparkler":"礼花棒","sparkling_wine":"起泡酒","sparrow":"麻雀","spatula":"锅铲","speakers_music":"音响","speedboat":"快艇","spice":"香料","spider":"蜘蛛","spiderweb":"蜘蛛网","spinach":"菠菜","spoon":"勺子","sport":"运动","sports_equipment":"运动器材","sportscar":"跑车","spotlight":"聚光灯","springroll":"春卷","sprinkler":"洒水器","squash_sport":"壁球","squirrel":"松鼠","stadium":"体育场","stained_glass":"彩色玻璃","stairs":"楼梯","starfish":"海星","starfruit":"杨桃","statue":"雕像","steak":"牛排","steamer_cookware":"蒸锅","stereo":"立体声音响","stethoscope":"听诊器","sticky_note":"便签","stingray":"鲼","stir_fry":"炒菜","stool":"凳子","stopwatch":"秒表","storefront":"店面","stork":"鹳","storm":"暴风雨","stove":"炉子","straw_drinking":"吸管","straw_hay":"干草","strawberry":"草莓","street":"街道","street_sign":"路标","streetcar":"有轨电车","stretcher":"担架","string_instrument":"弦乐器","stroller":"婴儿车","structure":"结构","strudel":"酥皮卷","stuffed_animals":"毛绒玩具","submarine_water":"潜水艇","sugar_cube":"方糖","suit":"西装","suitcase":"手提箱","sumo":"相扑","sun":"太阳","sunbathing":"日光浴","sundial":"日晷","sunfish":"翻车鱼","sunflower":"向日葵","sunflower_seeds":"葵花籽","sunglasses":"太阳镜","sunhat":"遮阳帽","sunset_sunrise":"日出/日落","surfboard":"冲浪板","surfing":"冲浪","sushi":"寿司","suv":"运动型多用途车","swan":"天鹅","swimming":"游泳","swimsuit":"泳衣","swing_playground":"秋千","swivel_chair":"旋转椅","sword":"剑","swordfish":"剑鱼","syringe":"注射器","tabbouleh":"塔布勒色拉","table":"桌子","tableware":"餐具","tachometer":"转速表","taco":"墨西哥玉米饼","taffy":"太妃糖","tambourine":"手鼓","tapas":"小吃","tapioca_pearls":"珍珠粉圆","taro":"芋头","tattoo":"纹身","tea_drink":"茶饮","teapot":"茶壶","teen":"青少年","telescope":"望远镜","television":"电视","tempura":"天妇罗","tennis":"网球","tent":"帐篷","tequila":"龙舌兰酒","teriyaki":"照烧","terrarium":"玻璃容器植物","terrier":"梗犬","textile":"纺织品","theater":"剧院","thermometer":"温度计","thermos":"保温瓶","thermostat":"恒温器","thunderstorm":"雷暴","tiara":"皇冠","ticket":"票","tiger":"老虎","timepiece":"时钟","tiramisu":"提拉米苏","tire":"轮胎","toad":"蟾蜍","toaster":"烤面包机","toaster_oven":"烤箱","toilet_seat":"马桶座","tomato":"番茄","tool":"工具","toolbox":"工具箱","tornado":"龙卷风","tortilla":"玉米饼","tortoise":"乌龟","toucan":"巨嘴鸟","tower":"塔","toy":"玩具","track_rail":"铁轨","tractor":"拖拉机","traffic_light":"红绿灯","trail":"小径","train":"火车","train_real":"真火车","train_station":"火车站","train_toy":"玩具火车","trampoline":"蹦床","tramway":"有轨电车线路","trash_can":"垃圾桶","treadmill":"跑步机","tree":"树","tricycle":"三轮车","tripod":"三脚架","trombone":"长号","trophy":"奖杯","trout":"鳟鱼","truck":"卡车","trumpet":"喇叭","tuba":"大号","tulip":"郁金香","tuna":"金枪鱼","tunnel":"隧道","turmeric":"姜黄","turntable":"唱盘","turtle":"乌龟","tuxedo":"礼服","typewriter":"打字机","ukulele":"尤克里里","umbrella":"伞","underwater":"水下","ungulates":"偶蹄类动物","urchin":"海胆","utensil":"用具","vacuum":"吸尘器","van":"面包车","vase":"花瓶","vegetable":"蔬菜","vegetation":"植被","vehicle":"交通工具","vehicle_toy":"玩具车","videogame":"电子游戏","vineyard":"葡萄园","violin":"小提琴","vizsla":"匈牙利猎犬","volcano":"火山","volleyball":"排球","vulture":"秃鹫","waffle":"华夫饼","wagon":"四轮手推车","wakeboarding":"滑水板运动","wallet":"钱包","walrus":"海象","warship":"军舰","wasabi":"芥末酱","washbasin":"洗脸盆","watch":"手表","water":"水","water_body":"水体","watercraft":"水上交通工具","waterfall":"瀑布","watering_can":"浇水壶","watermelon":"西瓜","watermill":"水车","waterpolo":"水球","watersport":"水上运动","waterways":"水道","wedding":"婚礼","wedding_cake":"婚礼蛋糕","wedding_dress":"婚纱","weight_scale":"体重秤","weimaraner":"维玛犬","wetland":"湿地","wetsuit":"潜水衣","whale":"鲸鱼","wheat":"小麦","wheel":"轮子","wheelbarrow":"独轮手推车","wheelchair":"轮椅","whisk":"搅拌器","white_bread":"白面包","white_wine":"白葡萄酒","whiteboard":"白板","willow":"柳树","winch":"绞盘","wind_turbine":"风力发电机","windmill":"风车","window":"窗户","windsurfing":"风帆冲浪","wine":"葡萄酒","wine_bottle":"葡萄酒瓶","winter_sport":"冬季运动","wonton":"云吞","wood_natural":"天然木材","wood_processed":"加工木材","woodpecker":"啄木鸟","woodwind":"木管乐器","workout":"锻炼","worm":"蠕虫","wreath":"花环","wrench":"扳手","wrestling":"摔跤","xylophone":"木琴","yacht":"游艇","yarn":"毛线","yoga":"瑜伽","yogurt":"酸奶","yolk":"蛋黄","zebra":"斑马","zoo":"动物园","zucchini":"西葫芦"}

const blob = await fetch('https://example.com/demo.jpg').then(response => response.blob())

const formData = new FormData()
formData.append('image', blob)
const json = await fetch('http://localhost:1643/classify', {
  method: 'POST',
  body: formData
}).then(response => response.json())

const result = json.labels.map(item => ({
  ...item,
  identifier: list[item.identifier]
}))

console.log(result)
```

</details>


> **响应示例**
> ```json
> {
>   "labels": [
>     {
>       "identifier": "Laptop",
>       "confidence": 0.985
>     }
>   ]
> }
> ```
