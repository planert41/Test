//
//  Dictionary.swift
//  EmoticonTest
//
//  Created by Wei Zou Ang on 7/25/16.
//  Copyright © 2016 Wei Zou Ang. All rights reserved.
//

//
//  Dictionary.swift
//  Main_2
//
//  Created by Wei Zou Ang on 7/12/16.
//  Copyright © 2016 Wei Zou Ang. All rights reserved.
//


//Smiley Emoticons
//😀😆😂😊😍😘😋😝🤑😎😔😕🙁😣😫😤😩😡😑😵😱😢🤤😭😓😴🤔😷🤒👺💩☠️🙏👍✌️👌💪💍💄💋👨‍👩‍👧‍👦
//🌶🥔🥜🍯🥐🍞🥖🧀🥚🍳🥓🥞🍤🍗🍖🍕🌭🍔🍟🥙🌮🌯🥗🥘🍝🍜🍲🍥🍣🍱🍛🍚🍙🍘🍧🍨🍦🍰🎂🍮🍭🍬🍫🍿🍩🍪🥛🍼☕️🍶🍺🍻🍷🥂🍸🍹🍾🥄🍴🍽
//🐔🐷🐮🦆🐗🐴🐌🐚🐍🦀🦑🐙🦐🐟🐊🐄🐪🐖🐓🦃🐇🍄🌾⚡️🔥💥❄️💧🍎🍋🍌🍉🍇🥑🍅🍆🥒🥕🌽
//🏳️‍🌈🇦🇷🇦🇺🇦🇹🇧🇷🇨🇦🇨🇺🇨🇷🇨🇳🇪🇹🇪🇺🇫🇷🇮🇷🇮🇩🇮🇳🇭🇰🇬🇷🇩🇪🇬🇭🇮🇶🇮🇪🇮🇹🇯🇲🇯🇵🇲🇽🇲🇾🇵🇰🇵🇷🇵🇹🇵🇱🇸🇬🇿🇦🇰🇷🇪🇸🇸🇪🇺🇸🇬🇧🇹🇭🇻🇳



//😍😋🤤👍
//😀😝😂😎
//😮🤔🤑😴
//😢😭🤥😑
//😤🤒😡💩
//
//🍩🍪🥐🥞🥓
//🍕🍔🌭🍟🍗
//🥗🍝🍖🍲🍛
//🍣🍜🌮🌯🥙
//☕️🍦🍰🍺🍷
//
//🍳🍱🍽🍮🍻
//🚗🏠🚌🏪⛱
//🎂🎁💑💼📆
//💸💳💵👔👖
//👨‍👩‍👧‍👦🔕🅿️🆕🛎
//
//🐮🐷🐔🦆🐑
//🐟🦐🦀🐳🐚
//🌾🥜🌽🥔🍼
//🦃🥚🧀🍫🍄
//🌱⛪️🕍🕌☸️
//
//
//🍵🌶🔥🍯🥑
//🍎🍐🍑🍈🍌
//🍓🍇🍋🥝🌹
//🍉🍒🍍🍆🥒
//🍅🥕🥔🍠🌰
//
//🇺🇸🇲🇽🇬🇷🇹🇭
//🇫🇷🇮🇹🇩🇪🇪🇸
//🇨🇳🇯🇵🇰🇷🇮🇳
//🇻🇳🇵🇭🇲🇾🇸🇬
//🇵🇹🇮🇷🇮🇪🇸🇪
//🇦🇷🇧🇷🇨🇴🇨🇺
//🇪🇹🇯🇲🇳🇱🇸🇳
//🇲🇳🇲🇦🇷🇺🇵🇪


import Foundation

var defaultEmojis:[Emoji] = []
var allEmojis:[Emoji] = []


struct Emoji {
    let emoji : String
    let name : String?
}

var Ratings: [String] = [
    
    "😡","😩","😓","😕","😋","😍","💯"
    
]

//😍😀😅😋😝🤑🙁😩😤😡😵🤤😭🤤😑😷




var Emote1Init: [String] = [
    "😍","😋","🤤","👍",
    "😀","😝","😂","😎",
    "😮","🤔","🤑","😴",
    "😑","😩","😢","😭",
    "😡","😤","🤒","💩"
]


var Emote2Init: [String] = [
    "☕️","🍩","🥐","🥞","🥓","🥚",
    "🍺","🍕","🍔","🌭","🍟","🍗",
    "🍷","🍝","🥗","🍲","🍖","🍢",
    "🌮","🌯","🍣","🍜","🍛","🥙",
    "🍦","🍰","🍪","🍫","🍧","🍭"
    
]


var Emote3Init: [String] = [
    "🐮","🐷","🐔","🦆",
    "🐟","🦐","🦀","🐙",
    "🌱","🐳","🐚","🥚",
    "🌾","🥜","🌽","🍼",
    "⛪️","🕍","🕌","☸️"

]

var Emote4Init: [String] = [
    "🍯","🍋","🌶","🔥",
    "🍵","🥑","🧀","🍉",
    "🍎","🍊","🍑","🍐",
    "🍌","🍄","🥕","🍅",
    "🍓","🍇","🥝","🌹",

    
]


var Emote5Init: [String] = [
    "🍳","🍱","🍽","🍮",
    "🚗","🏠","🚌","🏪",
    "🎂","💑","💼","📆",
    "👔","👖","💵","💸",
    "👶","🔕","🅿️","🆕"
    
]

var Emote6Init: [String] = [
    "🇺🇸","🇨🇦","🇲🇽","🇨🇺","🇦🇷",
    "🇫🇷","🇮🇹","🇩🇪","🇪🇸","🇧🇷",
    "🇨🇳","🇯🇵","🇰🇷","🇮🇳","🇹🇭",
    "🇻🇳","🇵🇭","🇲🇾","🇸🇬","🇨🇴",
    "🇵🇹","🇮🇷","🇮🇪","🇬🇷","🇷🇺"
    
]


var EmoteInits:[[String]] = [Emote1Init, Emote2Init, Emote3Init, Emote4Init, Emote5Init, Emote6Init]

//var Emote1Selected: [String] = []
//var Emote2Selected: [String] = []
//var Emote3Selected: [String] = []
//var Emote4Selected: [String] = []
//var EmoticonSelectedArray: [[String]] = [Emote1Selected, Emote2Selected, Emote3Selected, Emote4Selected]


var Emote1Display: [String] = Emote1Init
var Emote2Display: [String] = Emote2Init
var Emote3Display: [String] = Emote3Init
var Emote4Display: [String] = Emote4Init
var Emote5Display: [String] = Emote5Init
var Emote6Display: [String] = Emote6Init



var EmoticonArray: [[String]] = EmoteInits

//var EmoticonArray: [[String]] = [Emote1Display, Emote2Display, Emote3Display, Emote4Display]


var extras = "🐮🐔🐷🐙🍅🍠🐣🐌🐛🎭🎯🍳☝️⭐️⚠️🍖🍛🍴🍛🎃🎓💍🎈🎆🏆🎪🎮🔍🚽🗿🎮♨️♻️💊👌🔒"

var defaultEmojiSelection: [String] = [
    "🍩",
    "🥞",
    "🍔",
    "🍕",
    "🍣",
    "🍜",
    "🥗",
    "🍝",
    "🍖",
    "🌮",
    "🌯",
    "🥙",
    "🍗",
    "☕️",
    "🍺",
    "🍷",
    "🍦",
    "🍰",
    "🍢",
    "🍪",
    "🍧",
    "🍭"

]


var EmojiDictionary: [String:String] =

[
    "😍":"love",
    "😋":"tasty",
    "🤤":"amazing",
    "👍":"great",
    "😀":"good",
    "😝":"lol",
    "😂":"funny",
    "😎":"cool",
    "😮":"surprised",
    "🤔":"curious",
    "🤑":"pricey",
    "😴":"slow",
    "😢":"sad",
    "😭":"sob",
    "🤥":"lied",
    "😑":"meh",
    "😡":"furious",
    "😤":"angry",
    "🤒":"sick",
    "💩":"crap",
    "😩":"terrible",
    
    "🍩":"donut",
    "🥐":"pastry",
    "🥞":"pancake",
    "🥓":"bacon",
    "🍕":"pizza",
    "🍔":"burger",
    "🌭":"hotdog",
    "🍟":"fries",
    "🍲":"soup",
    "🥗":"salad",
    "🍝":"pasta",
    "🍖":"bbq",
    "🍣":"sushi",
    "🍜":"ramen",
    "🍚":"rice",
    "🍛":"curry",
    "🌮":"taco",
    "🌯":"burrito",
    "🥙":"pita",
    "🍗":"wings",
    "☕️":"coffee",
    "🍺":"beer",
    "🍷":"wine",
    "🍦":"icecream",
    "🍰":"cake",
    "🍢":"skewer",
    "🍪":"cookie",
    "🍧":"shavedice",
    "🍭":"candy",

    "🍳":"breakfast",
    "🍱":"lunch",
    "🍽":"dinner",
    "🍮":"dessert",
    "🚗":"delivery",
    "🏠":"restaurant",
    "🚌":"truck",
    "🏪":"24hour",
    "🎂":"birthday",
    "💑":"date",
    "💼":"business",
    "📆":"meeting",
    "👔":"formal",
    "👖":"informal",
    "💵":"cash",
    "💸":"expensive",
    "🔕":"quiet",
    "🅿️":"parking",
    "🆕":"new",
    "👶":"kid",
    "👨‍👩‍👧‍👦":"family",
    
    "🐮":"beef",
    "🐷":"pork",
    "🐔":"chicken",
    "🦆":"duck",
    "🐟":"fish",
    "🦐":"shrimp",
    "🦀":"crab",
    "🐙":"squid",
    "🌱":"vegetarian",
    "🐳":"seafood",
    "🐚":"shellfish",
    "🥚":"egg",
    "🌾":"wheat",
    "🥜":"peanut",
    "🌽":"corn",
    "🍼":"milk",
    "⛪️":"christian",
    "🕍":"kosher",
    "🕌":"halal",
    "☸️":"buddhist",
    
    "🍯":"sweet",
    "🍋":"sour",
    "🌶":"spicy",
    "🔥":"hot",
    "🍵":"greentea",
    "🍫":"chocolate",
    "🥑":"guacamole",
    "🧀":"cheese",
    "🍎":"apple",
    "🍊":"orange",
    "🍑":"peach",
    "🍐":"pear",
    "🍌":"banana",
    "🍄":"mushroom",
    "🥕":"carrot",
    "🍅":"tomato",
    "🍓":"strawberry",
    "🍇":"grape",
    "🥝":"kiwi",
    "🌹":"rose",
    "🍈":"melon",
    "🍉":"watermelon",
    "🍒":"cheery",
    "🍍":"pineapple",
    
    "🇺🇸":"american",
    "🇲🇽":"mexican",
    "🇬🇷":"greek",
    "🇹🇷":"turkish",
    "🇫🇷":"french",
    "🇮🇹":"italian",
    "🇩🇪":"german",
    "🇪🇸":"spanish",
    "🇨🇳":"chinese",
    "🇯🇵":"japanese",
    "🇰🇷":"korean",
    "🇮🇳":"indian",
    "🇻🇳":"vietnamese",
    "🇵🇭":"filipino",
    "🇹🇭":"thai",
    "🇲🇾":"malaysian",
    "🇵🇹":"portugese",
    "🇨🇦":"canadian",
    "🇬🇧":"british",
    "🇮🇷":"persian",
    "🇮🇪":"irish",
    "🇸🇪":"swedish",
    "🇦🇷":"argentinian",
    "🇧🇷":"brazilian",
    "🇵🇪":"peruvian",
    "🇨🇴":"colombian",
    "🇨🇺":"cuban",
    "🇪🇹":"bolivian",
    "🇯🇲":"jamaican",
    "🇳🇱":"dutch",
    "🇸🇳":"senagalese",
    "🇷🇺":"russian",

    "❌🍖": "vegetarian",
    "❌🌽": "gluten free",
    "❌🥜":"peanut free",
    "❌🥛":"non dairy",
    "🇹🇭🍝":"pad thai" ,
    "🍖🍡":"meatball",
    
    "🎃👻": "halloween",
    "🐔🍗": "chicken wing",
    "🐔🍚":"chicken rice",
    "🐔🍛": "chicken curry",
    "🐷🍛":"pork curry",
    "🐟🍛":"fish curry"
    
    
]


//[
//        "💯":"best",
//        "😍":"amazing",
//        "😋":"good",
//        "😕":"ok",
//        "😓":"bad",
//        "😩":"terrible",
//        "😡":"worst",
//        "😢":"sad",
//        "💩":"poop",
//        "😑":"grrrr",
//        "😝":"lol",
//        "🍴":"food",
//        "🚗":"delivery",
//        "🔒":"private",
//        "🍳":"breakfast",
//        "🍱":"lunch",
//        "🍽":"dinner",
//        "🌙":"latenight",
//        "☕️":"coffee",
//        "🍦":"icecream",
//        "🍮":"dessert",
//        "🍺":"beer",
//        "🍷":"wine",
//        "🎁":"surprise",
//        "🎷":"music",
//        "🎨":"art",
//        "🎭":"theatre",
//        "📷":"photo",
//        "🎪":"attraction",
//        "📍":"local",
//        "🗿":"exotic",
//        "🍔":"burger",
//        "🍕":"pizza",
//        "🍟":"fries",
//        "🍗":"wings",
//        "🍛":"curry",
//        "🍣":"sushi",
//        "🍜":"ramen",
//        "🍰":"cake",
//        "🍲":"soup",
//        "🍝":"pasta",
//        "🍞":"bread",
//        "🍩":"doughnut",
//        "🍫":"chocolate",
//        "🍪":"cookie",
//        "🎤":"karaoke",
//        "🍋":"sour",
//        "🍯":"sweet",
//        "🔥":"spicy",
//        "🐓":"chicken",
//        "🐄":"beef",
//        "🐖":"pork",
//        "🐟":"fish",
//        "🐚":"shellfish",
//        "🐙":"seafood",
//        "🍀":"vegetarian",
//        "🍠": "potato",
//        "🍎":"fruit",
//        "🍤":"shrimp",
//        "🍼":"milk",
//        "🌽":"corn",
//        "🌾":"glutenfree",
//        "🍄":"mushroom",
//        "🌰":"nuts",
//        "🍚":"rice"]




/*
 
 "🇦🇺":"aus"
 "🇦🇹"
 "🇧🇪"
 "🇧🇷"
 "🇨🇦"
 "🇨🇱"
 "🇨🇳"
 "🇨🇴"
 "🇩🇰"
 "🇫🇮"
 "🇫🇷"
 "🇩🇪"
 "🇭🇰"
 "🇮🇳"
 "🇮🇩"
 "🇮🇪"
 "🇮🇱"
 "🇮🇹"
 "🇯🇵"
 "🇰🇷"
 "🇲🇴"
 "🇲🇾"
 "🇲🇽"
 "🇳🇱"
 "🇳🇿"
 "🇳🇴"
 "🇵🇭"
 "🇵🇱"
 "🇵🇹"
 "🇵🇷"
 "🇷🇺"
 "🇸🇦"
 "🇸🇬"
 "🇿🇦"
 "🇪🇸"
 "🇸🇪"
 "🇨🇭"
 "🇹🇷"
 "🇬🇧"
 "🇺🇸"
 "🇦🇪"
 "🇻🇳"
 */

/*
 public var tags = String()    {
 
 
 didSet {
 /*
 // Loop Through Array
 
 
 for EmoteArray: [String] in EmoteInits {
 
 // Loop Through Emoticoins
 
 var EmoteSelectedArray: [String] = []
 
 // Add it to the Selected Emoticon Array
 if EmoteArray == Emote1Init {
 EmoteSelectedArray = Emote1Selected
 }
 else if EmoteArray == Emote2Init {
 EmoteSelectedArray = Emote2Selected
 }
 else if EmoteArray == Emote3Init {
 EmoteSelectedArray = Emote3Selected
 }
 else if EmoteArray == Emote4Init {
 EmoteSelectedArray = Emote4Selected
 }
 var EmoteDisplayTemp = EmoteArray
 
 for Emoticon: String in EmoteArray  {
 
 // If Emoticon is Tagged
 
 if tags.containsString(Emoticon) {
 
 // If is tagged, remove emoticon from init
 EmoteDisplayTemp.removeAtIndex(EmoteDisplayTemp.indexOf(Emoticon)!)
 
 if EmoteSelectedArray.contains(Emoticon) {
 
 // pass nothig if emoticon is selected and is already in selected index
 
 } else {
 
 //Add selected emoticon to the selected index
 EmoteSelectedArray.append(Emoticon)
 }
 }
 
 // IF Emoticon is not tagged
 else {
 if EmoteSelectedArray.contains(Emoticon) {
 EmoteSelectedArray.removeAtIndex(EmoteSelectedArray.indexOf(Emoticon)!)
 }
 }
 }
 
 
 if EmoteArray == Emote1Init {
 Emote1Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote1Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote2Init {
 Emote2Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote2Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote3Init {
 Emote3Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote3Selected = EmoteSelectedArray
 }
 else if EmoteArray == Emote4Init {
 Emote4Display = EmoteSelectedArray +  EmoteDisplayTemp
 Emote4Selected = EmoteSelectedArray
 }
 
 
 EmoticonArray = [Emote1Display, Emote2Display, Emote3Display, Emote4Display]
 
 
 }
 */
 }
 
 }*/












