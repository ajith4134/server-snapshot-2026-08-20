# Transcript — Video by gojutechtalk

Channel: gojutechtalk  |  Duration: 00:00
Source: https://www.instagram.com/p/Da1XG9qgd4E/
Transcript source: whisper:small

**[00:00]** how you can embed a Trojan or put an exploit into an SLM. Models are just numbers, and binaries are just numbers. We just pre-build the bad stuff directly into the neural network. How does that not kill the entire neural network behavior? Because it just skips right over it. The way that we wire up the neural network is at this layer, we jump all the way over here. These layers that are part of the neural network, they're completely ignored. They're never actually executed. So the behavior of the neural network

**[00:30]** continues to perform and do all the stuff that it's supposed to do. And now we've embedded a Trojan that is pre-built code, that's object code, that all it needs to do is be linked into something, then we can take over somebody's machine. We've been able to embed these types of hacks for decades in things like JPEGs. That's why when your email system is saying, I'm not gonna download these pictures because if you don't trust this, the picture itself might be a virus. In that data file, you can embed things

**[01:01]** that can execute and do bad stuff. The same concept applies to anything that consists of data. Where it starts to get a little tricky. If you wanted this to be universally executable, if you want this to Trojan itself on some series, ARM processors, AMD and Intel x86, and then something else, you have to abstract the binary information. So it's a more generic object representation, something like Java's object code

**[01:33]** or the .NET framework object code. So then it will do a translation layer from that object code that's more general to the specific architecture that's running on. I think people that think that it's not possible, it's just a neural network, it's just data. They're not considering that these things can be multi-purposed. This is the playbook for the XC-UDL's backdoor. They didn't embed any malicious code into the repo. They embedded object code that were supposedly tests at the point of deployment.

**[02:03]** And then when those tests were unpacked from the tar file, it turns out that those tests were object code when linked together, they create a backdoor through SSH. And then they assembled them, they used the resident linker, already there to link the library. And Bob's your uncle, you're cooked. I absolutely agree with this, Ted. I think that we need to get knowledge into good people's hands. This is probably a very elegant way of saying it,

**[02:34]** that it's a matrix embedded attack. That's basically exactly what it is. It's just a massive matrix. And just one section of the matrix embeds this malicious code.