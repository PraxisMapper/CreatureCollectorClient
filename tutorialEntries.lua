tutorialDataSets = 
 {
    first = {
         {image = "themables/TutorialGuy.png", text ="test", specialFunc = nil, },
         {image = "themables/TutorialGuy.png", text ="test2!", specialFunc = testSpecial, }
    },
    placeholder = {
        {image = "themables/TutorialGuy.png", text ="placeholder text TODO REPLACE THIS", specialFunc = nil, },
    },
    story1 = {
        {image = "themables/TutorialGuy.png", text ="Oh, wonderful, you finally woke up. Gonna have to give you the short version of the usual speech today, sorry.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You are a dimension travelling demigod known as a WorldWeaver. You can find or create planes of existence on a whim.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Physically, you are immortal and cannot permanently die. Mentally, however.....", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Our kind is quite prone to extended blackouts and amnesia, usually from long, brutal fights with other WorldWeavers. We all know our own weakness, we all exploit it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You just woke up from one of those! Don't worry too much about vengeance, we all just accept the reset in our society. No one's gonna hold grudges that you were gone for a while or forgot who they were.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Right now, we're all fighting over a place called |location. It's pretty important. It's the center of the world!", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Not just this plane. All planes. |location is the very center of all creation. And we're in an all-hands-on-deck brawl to decide who owns it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Looks like we coalesced into 4 separate teams this time. I have to admin, I also wasn't awake when that happened. You'll want to pick one pretty quick before you get amnesia again.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="If you need help picking a team, I suggest thinking about apples while looking at your choices. Always works for me!", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="", specialFunc = JumpToTeam, },
    },
    story2 = {
        {image = "themables/TutorialGuy.png", text ="Alright, great! Now you'll probably want to wander around for a while and find some memory fragments of creatures or minions you could use to stake your claims.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Uh, you remember I said how we all tend to get amnesia every so often? ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Yeah, some of these memory fragments are pretty wild. Might not match up to what you would expect. But somewhere out there, they're real. Usually.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Wander around, put some memory fragments together, and start using them to control some places you find for your team. There's a few different ways you'll get to use them soon.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="I totally remember some sparkly, shiny rat that a lot of people thought was super cool. Very popular here for quite a while. Do you remember it? Think about that glittery party rat, and make it real. You'll figure it out.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Oh, more things to throw at you right away: In the menu, if you tap the Active Challenge line, you'll toggle it on or off. When it's on, you'll get a minigame. Complete it to get an additional, stronger creature.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Or turn it off to just explore and chill. Maybe you don't want to check your phone every 5 seconds, and just enjoy a hike through |location and also somewhere else at the same time. I get it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Well, I've got to go. You're awake, up to speed, and unfortunately not on my team. I'll be off now, quite busy these days, good luck taking over |location!", specialFunc = nil, },
    },
    proxyPlayOOB = {
        {image = "themables/TutorialGuy.png", text =".....Oh, I see a temporary issue. You're not IN |location. The very important place where the whole game happens.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="That's not a problem. We're plane-creating demigods. We can be anywhere in |location we want!", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You'll have to Proxy-Play, but that's a cool thing. Everyone else can do it too, even if they're in |location. You simply won't be allowed to stop if you're not physically in the state.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="For now, you should pick one of the 4 suggested places to use as your Proxy Point.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="That will be where you start in-game every time you open up the app from now on. You can change this anytime, but you do need to use a token so you don't change it too often.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Whatever distance you walk in your real-life, non-|location position, will be applied to your Proxy Point in-game. for this session. Next time you open the game, you'll be back at your chosen point.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="In the future, once you get used to the address codes you see here, you can pick a custom Proxy Point anywhere in the state to use.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="If you need to accomplish things far away and aren't up for a cross-state road trip, Proxy-Play lets you get it done.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="", specialFunc = JumpToProxy, },
    },
    controlIntro = {
        {image = "themables/TutorialGuy.png", text ="This is it, time to start claiming spaces for your team. Specifically, shared spaces. Public areas and the like.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Here, you'll automatically be putting each of your creature's full power into a selected place for your team.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Note that you can claim a place with your team by getting your team to have the most offense power in an area. You can put a creature down without knocking other people's out.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You'll compare which team is doing better by how much space on the map each team owns. Bigger places are more points! Smaller places are still worth taking, since they'll be less contested and last longer.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You can kick all the creatures out of an area by fighting. The power structure in a place resembles a pyramid. You can clear a place by winning against EITHER the strongest creature, OR clearing a whole 'row' from the bottom of the pyramid.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="So, the top row of the pyramid has 1 creature. The next has 2. After that is 3, 4, and then 5. Kicking out every creature in a row means the whole thing collapses, and even the creatures too strong for you to fight 1 on 1 get sent home.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Team score is also split up across shares. They're divided up like pirate treasure, or maybe a ponzi scheme. The top-most creature gives 16 shares to its team. The 2 under get 8 shares. Third row gets 4 each, 4th row gets 2, and the bottom 5 get 1 share apiece.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="The place's total score is divided by the number of shares claimed, which is some number between 16 and 51 depending on how many creatures are present. Then each share's point value is given to the appropriate team.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="This way, everyone contributes to the team's score. No single person can just walk in and claim everything in town, since each creature you have can only claim one place.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Leaderboards are available to see which team has the most points across the state. Followerboards are not, but they're just a leaderboard you sort backwards.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Good fun, have luck, game well, all that jazz.", specialFunc = nil, },
    },
    coverIntro = {
        {image = "themables/TutorialGuy.png", text ="Not that long, ago, when I explained out that we can find or create planes to explore, you may have asked yourself a question.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="'Self, why would I not just create an |location where I am not fighting against other WorldWeavers for control? Why not imagine one I have all to myself?'", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Congrats, you've invented Cover mode. An |location all to yourself to explore, or conquer, or draw pictures over with your creatures.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Your fragments used here also don't take away from the ones you could use in Compete mode, so feel free to switch between them when you feel like it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You may also be asking yourself 'Why do I not just imagine an |location that I already control by myself?' Great question, and there's an answer.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="When you weave a world that way, you actually only get to pick the details you imagine. If you can't think of a thing, you don't get to determine how it is.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="This usually means there's some rebellion hiding in the shadows, ready to do what they can to get you out of power and ensure you never return to their world again. Unless you choose to imagine every single inhabitant and their life as entirely loyal to you, and that's HARD to think of all at once.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="It's much better to start with the general condition, and to work naturally through the world to get what you're looking for, instead of jumping in at what would be the climax of the story.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Anyways, tap the map to pick a spot where you want to place a creature to scout. Use fragments of that creature to power it up and cover a larger area.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You can add more later by tapping on the circle for that creature. If you change your mind, you can set the fragments to 0 to get them back and place them somewhere else later.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="There are also leaderboards for this mode, to see who has covered the most of |location in their own private world. Space overlapped by multiple creatures won't get counted twice for that!", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="And finally, you can see a map of your full Cover mode progress from the entry in the menu. It'll zoom out to show you everything you've placed. The state borders will show up if you've got creatures scouting near enough to them.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Enjoy your time by yourself here! I'll see you back on the battlefield later.", specialFunc = nil, },
    },
    competeIntro = {
        {image = "themables/TutorialGuy.png", text ="Alright, so let's take a different approach to this whole battle for |location thing. Instead of specific places in Control mode, let's compete for area.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Compete mode is just that. Each team can pick areas on the map, nicely split along even lines, and place creature fragments in it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="All team members can add to the creature's power, and opposing teams will have to fight it individually to take it down. The opposite of Control mode, where each individual creature is only as strong as it's owner could get it.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="The score here is how much area is covered under the circle. Each fully-covered area as you see it split is worth 400 points. You get partial credit, and overlapping with another team's creature doesn't affect your team's score.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="It works a lot like Cover mode, except your team can cooperate to make big circles and other teams can take them down. ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Oh, and that you have to touch the map tile that's the center of a circle to contribute to it. You can start new circles under existing ones if you want to be sneaky about thtings.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="If you want to take down an opposing team's area, you tap the center of it, pick a creature of yours, and attack with all the fragment you have available for it. If it can win the fight, you'll take their area down.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="There's also a map available on the menu that updates every 15 minutes, if you want to see where teams have made progress.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Lastly, using a creature in Compete mode doesn't lock that creature out of Control or Cover mode. Compete and Cover modes don't share fragments, so you can use a creature to it's full power in both.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Yes, you can remember a creature once and then put it to work in 3 different versions of |location. You didn't forget about it in any of them. This is important, in case we find another |location to battle in.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="I'm done here. Go forth, scout the state, and help your team out. ", specialFunc = nil, },
    },
    upgradesIntro ={
        {image = "themables/TutorialGuy.png", text ="Here on the Upgrades screen, you can put your creatures to work for you. ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Tap the ? space and pick one of your available creatures to start working towards that task,", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You can't use a creature here that you've placed in Control mode, and vice versa. You CAN stil use them in Cover mode. Cover mode is cool like that.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="The most important one here is the ProxyPlay token, to change where in the state you're playing at. You can get one of those every week if you have a creature there.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="But the entry that gives you 2 fragments a day for the allotted creature is nothing to shake a stick at either.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="The Cancel button on each entry will let you use that creature again in Control mode and stop gaining progress for that specific task. Pretty standard Cancel button.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="ProxyPlay and Team Swap tokens are used on the Options screen. If you didn't already set a ProxyPlay point when you started, you should have 1 available to use already.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="That's all there is to see here, really. It's important but not exciting like chasing down those goofy birds is.", specialFunc = nil, },
    },
    helpProxy = {
        {image = "themables/TutorialGuy.png", text ="ProxyPlay is a special setup where you start your game session somewhere other than your real-world position.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You get teleported to your ProxyPlay point when the game starts, and then all your real-world walking is applied to that point.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="This lets you explore places in-game you couldn't get to normally!", specialFunc = nil, },        
        {image = "themables/TutorialGuy.png", text ="Turn ProxyPlay off in the Options screen to return to your real-world location in-game.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You will need to spend a ProxyPlay token to change your proxy location, or to restart after turning it off.", specialFunc = nil, },
   },
   graduation = {
        {image = "themables/TutorialGuy.png", text ="Hey, congratulations! Got special news for you.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You've walked through X spaces and caught Y creatures since you started playing Z days ago! ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="I hope you've gotten out and done a lot of exploring, both in-game and in your local area. Maybe built some healthy habits along the way.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Since you've gotten this far, I'm going to say that you've won. You can graduate any time you want now. ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="In the options menu, you can pick Graduate, and move on from this game if you want. You'll get to leave a permanent mark on the game too! ", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="You'll be able to pick any creature you've caught, and permanently boost their spawn rate somewhere for everyone!", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Your account data will also get reset. If you want to move on, it's a great excuse to keep going without me.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="But if you want to keep playing from the start, and possibly graduate again, I won't stop you.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="It means a lot to me that you kept playing this long. I really do appreciate seeing you hit the end.", specialFunc = nil, },
        {image = "themables/TutorialGuy.png", text ="Remember, the Graduate button is in the Options menu when you're ready. Thanks again!", specialFunc = nil, },
   },
}