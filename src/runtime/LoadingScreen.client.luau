local Players=game:GetService("Players")
local RF=game:GetService("ReplicatedFirst")
local TweenService=game:GetService("TweenService")
local me=Players.LocalPlayer
local playerGui=me:WaitForChild("PlayerGui")
playerGui.ScreenOrientation=Enum.ScreenOrientation.Sensor
local korean=tostring(me.LocaleId or ""):sub(1,2)=="ko"
local bg,line,ink,muted,accent=Color3.fromRGB(10,33,73),Color3.fromRGB(64,104,170),Color3.fromRGB(240,245,252),Color3.fromRGB(196,212,236),Color3.fromRGB(54,226,208)
local yellow,outline,paper=Color3.fromRGB(255,216,74),Color3.fromRGB(10,8,6),Color3.fromRGB(248,248,244)
local DOODLE={w=512,h=743,palette={0xff29e4fe,0xff70b9d7,0xff06080a,0xff222e4b,0xfff4f8f8},pixels="a293d7a482d35a474d41a468d46a448d65a445d69a438d76a433d80a428d106a404d111a397d119a388d60c21d44a379d62c28d45a376d59c34d44a372d44c2d13c38d46a368d40c60d46a364d40c64d45a360d40c68d45a348d47c74d44a343d48c101d21a339d46c108d20a334d43c117d19a329d44c123d17a325d44c128d16a322d44c131d16a319d44c135d15a316d43c139d15a314d35c149d14a311d34c153d15a307d34c157d14a295d42c162d14a291d41c167d13a287d41c172d13a284d40c176d12a282d40c178d12a280d40c181d12a277d40c184d12a275d39c186d12a274d37c190d12a270d37c193d13a264d30c206d13a258d32c209d13a255d32c213d13a250d33c216d14a247d34c218d13a245d34c221d13a241d35c223d17a235d35c226d17a232d35c229d18a227d35c233d18a222d35c238d18a218d33c244d18a215d32c249d16a213d31c254d15a211d30c257d15a209d28c262d13a207d28c265d12a205d27c269d11a202d27c272d12a199d27c275d11a193d30c278d11a190d31c280d12a187d31c283d11a185d31c285d11a183d31c287d12a181d30c290d12a179d29c292d12a177d28c209d8c79d12a174d23c215d11c77d13a173d20c217d13c77d13a170d20c217d16c76d13a170d19c217d17c77d12a169d19c216d20c76d13a167d18c217d21c77d12a166d18c217d23c77d12a163d18c218d13b2d9c77d12a163d17c218d12b5d8c78d11a161d18c219d11b6d8c78d11a160d18c219d10b8d8c78d11a159d18c219d10b9d9c77d11a157d19c220d9b11d8c77d11a156d19c220d9b12d8c78d10a154d20c220d10b12d8c78d10a152d19c223d9b13d8c78d10a151d18c202d19c3d9b14d9c77d10a149d19c202d32b15d8c77d11a146d19c203d32b16d8c77d11a145d19c203d33b17d7c78d10a144d19c203d33b18d7c78d10a142d20c204d33b18d8c77d10a141d20c205d32b19d9c76d11a139d20c206d10b6d15b20d16c69d11a138d19c208d9b15d6b21d19c66d11a137d18c210d8b43d21c64d11a136d18c211d8b43d23c62d11a135d17c213d8b43d25c60d11a134d17c214d8b44d25c59d11a133d16c217d7b45d3b5d16c58d12a132d16c218d4b59d14c57d12a131d16c220d2b5cb57d11c57d12a130d16c224b4d2b58d9c57d11a130d15c227b2d4b58d8c56d12a130d14c229d5b58d8c56d12a129d14c230d6b56d9c56d11a129d14c180d8c42d8b54d10c56d11a128d14c176d48c7d9b52d10c57d11a127d14c173d70b49d11c56d12a126d14c160d85b46e2d10c57d11a127d13c158d89b44e4d8c58d11a127d13c155d92b44e5d5c59d11a127d13c151d97b43e7d2c61d11a127d12c148d101b42e9c61d11a127d12c146d104b41e9c61d12a127d12c125d11c6d108b37d5e7c61d13a126d12c122d73c9d47b35d12ec61d13a127d12c118d72c31d29b35d13c61d14a126d12c117d58c58d18b35d12c61d14a127d12c115d57c68d10b35d13c60d14a127d12c112d57c73d8b36d14c59d14a127d12c110d56c76d8b37d15c56d14a128d11c108d56c79d7b38d17c54d13a129d11c105d56c82d7b38d19c51d13a129d12c102d52c88d8b38d24c45d13a130d11c96d38c109d8b38d26c42d13a131d11c92d38c112d9b39d26c40d13a132d11c89d38c115d9b39d27c39d12a133d11c87d38c117d8b40d28c37d13a133d11c85d38c119d8b16d6b19d29c34d13a134d11c83d38c120d8b16d8b17d33c30d14a134d11c81d37c123d8b15d9b17d35c28d13a135d11c78d36c127d7b14d12b15d8c4d26c25d14a135d11c75d32c134d7b12d15b14d8c7d25c21d15a136d11c72d32c136d8b10ed16b14d8c10d23c19d15a137d12c69d31c139d8b9e3d15b14d8c11d23c16d16a138d12c67d31c141d9b3d3e6d15b13d8c12d23c14d16a140d11c65d30c144d15e6d17b12d7c14d22c11d17a141d11c63d29c147d15e6d5c3d10b11d7c17d20c9d17a142d12c60d29c149d14e8d2c6d10b9d8c20d17c8d17a144d12c58d26c153d14e8c8d11b8d8c22d15c6d18a145d12c57d24c157d13e4c13d12b6d7c24d15c4d17a148d12c55d23c160d12ce2c15d12b4d8c26d14c2d17a149d12c54d21c164d9c21d13bd9c27d32a150d11c53d20c167d6c24d22c28d30a151d12c51d19c200d20c29d29a152d12c49d19c202d20c30d27a154d11c48d19c205d18c30d25a156d11c46d19c209d15c31d22a159d12c42d21c211d13c32d21a161d11c41d20c215d9c34d20a162d12c38d21c259d19a164d11c36d22c260d18a165d12c34d22c261d17a166d12c33d22c262d16a168d12c31d21c264d14a170d13c30d18c267d11a174d12c29d17c269d11a174d13c27d16c270d12a175d13c25d16c134d15c9d21c92d12a175d13c24d16c130d58c84d11a177d13c22d16c124d76c73d11a177d14c20d16c117d89c68d11a178d14c18d16c110d101c64d11a179d14c16d16c106d110c60d11a179d15c15d15c104d117c56d11a180d16c12d14c103d124c52d11a181d16c11d13c100d130c50d11a182d17c9d12c98d141c42d11a182d19c6d13c84d71e18d70c38d11a183d21c2d13c81d65e42d59c35d11a184d34c79d61e62d48c33d11a186d32c77d56e77d42c31d11a187d31c75d50e91d38c29d11a189d28c74d47e99d38c26d11a190d27c71d46e107d37c23d11a191d27c66d47e113d37c20d11a192d26c54d55e120d39c14d12a193d25c51d44e144d32c11d12a195d23c49d40e152d32c9d12a199d19c47d40e157d32c6d12a201d17c45d40e160d33c3d13a203d15c43d40e164d46a206d13c42d39e168d44a207d12c40d38e174d41a207d12c39d36e181d36a208d11c37d25e2d7e192d30a208d11c34d25e207d27a208d11c29d27e212d26a207d11c26d29e215d24a207d11c24d29e218d23a207d11c22d29e222d23a205d11c21d29e225d22a204d10c20d29e228d22a203d10c18d29e233d21a201d9c17d28e238d20a200d9c13d27e245d20a198d9c11d26e37d17e197d18a197d9c10d26e33d35e186d18a195d10c7d101e49d11e122d18a194d10c5d107e23d38e118d18a193d10c4d173e115d19a191d11cd178e113d20a189d193e111d20a188d196e109d20a187d212e94d20a186d215e93d19a185d88b8d121e93d19a183d83b17d122e90d18a182d59b54d118e84d16a181d48b69d39b21d56e83d17a179d31b90d13b47d57e79d17a178d25b159d57e77d18a176d22b164d61e72d18a175d18b171d60e71d18a174d15b67d9b6d8b102d47e67d18a172d14b66d31b99d57e56d17a172d12b66d36b100d57e53d17a170d12b66d47b93d58e50d17a169d12b65d56b96d50e49d15a169d12b64d60b96d50e47d14a169d11b64d65b94d50e46d14a167d12b63d73b90d49e45d13a167d12b63d81b85d53e39d13a165d12b63d87b84d53e36d12a165d12b63d93b92d42e34d12a163d13b62d98b94d40e30d12a163d12b63d100b94d43e26d12a162d12b62d103b95d42e24d12a162d11b63d104b97d41e22d12a162d11b62d106b100d40e19d12a161d12b52d117b103d39e15d13a161d12b37d133b105d39e11d14a161d12b21d4b7d140b106d61a161d13b16d158b3d6b95d60a161d16b10d123c2d50b91d59a161d147f5d55b11d10b64d59a161d145cf7d56b6d16b60d11a4d44a162d144cf8d58b2d27b51d11a6d41a159de6d140cf9cd93b44d10a9d39a156d3e8d57b4d77f11d98b39d11a13d33a157d3e10d51b11d74f12d35b3d67b32d11a15d30a158d2e11d36b5d8b15d71f12d35b7d69b27d11a21d22a159d3e10d31b36d67f13d35b15d67b22d11a22d5a5d8a162d3e9d29b40d65f13d36b17d68b19d11a201d4e7d13b58d63f14d37b20d69b14d11a202d4e5d11b61d63f14d38b21d70b12d11a202d5e2d11b63d61cf14d39b21d73b9d11a202d18b63d60cf14d40b20d80b2d11a202d18b64d59cf14d41b20d93a203d17b64d59f14d42b20d93a202d18b63d59f14d43b19d94a202d17b64d58f13d44b20d94a202d17b64d58f11d46b20d94a202d16b65d58f10d47b20d95a201d16b65d57f10d49b19d96a199d17b65d56f10d62b6d98a198d16b66d55f10d66b3d67f3d29a197d16b66d52f13d135f6d27a197d16b67d49f14d135f7d28a195d16b68d48f15d134f8cd27a196d15b68d47f15d134f9cd27a195d16b68d46f15d134f10d29a194d16b68d45f15d58b4d72f11d29a194d16b68d45f13d56b11d68f11d30a194d16b68d44f12d56b15d65f10cd31a194d16b68d44f10d57b17d62f11cd32a195d15b68d43f10d57b20d59f12d33a195d15b68d43f10d57b21d57f12d35a195d14b68d42f10d57b22d56f12d36a196d12b69d41f10d58b22d54cf13d36a197d11b69d40f10d59b22d53cf13d37a197d11b69d39f11d58b23d53f13d37a197d11b70d37f12d59b23d52f13d38a196d12b70d36f12d60b23d51f13cd38a196d12b70d35f13d59b24d50f13cd39a196d12b70d34f13d60b24d50f12cd40a195d12b72d32f13d60b25d49f12d42a195d12b72d31f13d60b26d48f12d43a195d12b72d31f12d60b27d47f12d44a195d11b73d31f10d62b27d46cf11d45a194d12b73d31f8d63b29d44cf11d46a194d12b74d31f6d64b29d44f12d46a194d11b75d32f3d66b29d43f12d47a193d12b76d99b30d42f12d48a193d12b76d99b30d41f12d48a194d12b77d97b31d40f12cd47a195d12b77d96b32d39f12d48a195d12b79d94b33d38cf11d48a196d12b80d92b35d37f10cd48a197d12b81d91b35d36f11d49a197d11b83d89b36d35f11d50a197d11b84d87b37d34f12d50a197d11b86d85b37d34f11d50a197d11b88d84b37d34f10d51a197d11b90d81b38d33f10d52a196d11b95d76b39d31f11d53a196d11b97d73b40d30f10cd54a195d12b104d65b42d28f10cd55a195d11b109d60b43d27f11d56a195d11b118d50b44d27f10d56a196d11b122d44b46d26f10d57a196d10b129d37b47d26f9d57a197d10b135d28b51d26f7d57a198d10b146d12b56d27f5d57a198d11b214d29cd58a199d11b214d88a199d11b215d87a199d11b215d86a200d11b216d85a200d11b217d84a200d11b218d83a200d11b218d83a199d11b112d11b97d82a199d11b110d13b98d80a200d11b108d16b99d78a200d11b106d18b100d77a199d12b105d19b101d75a199d13b104d19b105d72a199d12b104d19b112d65a200d12b103d16eb119d61a199d12b104d16eb123d56a199d13b103d18b126d52a200d13b103d20b127d48a201d12b104d21b134d38a202d13b103d24b135d33a204d12b104d26b137d28a204d13b104d28b146d16a205d12b104d32b147d12a205d12b104d10b2d23b145d11a205d11b105d9b4d24b143d11a204d12b105d9b6d25b140d10a205d11b106d9b8d26b136d11a205d11b106d8b12d25b134d11a204d11b107d8b14d25b132d11a204d11b107d7b16d27b129d11a204d11b108d6b18d28b126d11a204d10b110d3b22d29b122d12a203d11b139d28b119d11a204d11b141d30b115d11a204d11b143d31b111d12a203d12b145d32b108d12a203d12b147d34b104d11a204d11b150d34b102d11a203d12b152d36b98d11a203d12b155d38b92d11a203d12b161d39b86d11a203d12b163d40b83d11a203d12b165d44b76d12a203d11b169d46b71d12a202d12b172d47b67d11a203d11b179d50b58d11a203d11b181d56b49d12a151d39a13d11b184d55b47d11a150d43a10d11b191d49b47d11a144d51a8d11b196d45b46d11a142d54a2da4d11b199d42b45d12a138d58a2d3a2d11b205d36b45d12a137d60ad15b209d33b45d11a134d64ad16b216d24b46d11a131d67ad16b223d16b46d11a127d29b10d9b15d9ad17b284d11a123d30b38d8ad18b283d11a121d27b44d27b281d11a117d30b46d30b278d11a114d29b50d7ad25b275d10a102d5a4d30b53d7ad30b270d11a98d40b55d7ad32b267d11a95d40b59d7ac3d31b265d11a93d39b62d7ac7d30b262d10a92d37b66d7ac8d35b255d11a82d44b69d7ac10d36b252d11a78d46b72d7c15d33b250d11a76d43b77d7c17d33b248d11a73d44b79d7c19d34b245d11a72d44b80d6ac21d36b240d12a70d45b81d6ac23d37b237d12a59d56b81d6ac25d37b235d11a57d44c4d12b80d6ac31d34b231d12a52d46c8d11b79d7ac36d37b223d12a50d38c4d3c12d10b79d7ac38d40b218d12a46d39c23d10b78d7ac40d41b215d11a43d41c26d9b78d7ac42d41b212d12a39d43c28d9b78d7ac44d40b211d12a36d44c30d10b77d7ac46d40b209d11a35d44c32d10b77d7ac47d42b206d11a31d37c44d10b75d8ac47d44b203d12a18d47c47d11b74d8ac46d53b195d12a13d49c51d10b74d8ac46d13c6d36b193d11a12d49c53d11b73d8ac45d12c14d32b191d11a9d50c55d11b72d9ac45d12c16d32b189d11a6d44c65d10b71d10ac45d11c19d33b186d11a2d45c68d11b68d12ac44d12c21d34b182d57c71d10b66d13a2c44d11c24d34b180d55c73d10b64d15a2c44d11c26d34b178d52c77d9b61d17a3c44d11c35d30b172d50c80d9b59d18a4c44d10c39d30b169d34c96d9b57d19a5c43d11c41d31b166d31c100d9b54d18a8c42d11c44d33b162d29c102d9b50d21a9c42d11c45d34b159d28c104d9b49d19a12c41d11c47d36b156d25c108d9b47d18a14c40d12c47d39b152d22c112d9b47d15a17c40d11c49d41b148d19c116d9b47d13a19c39d12c49d44b145d16c119d9b47d12a20c39d11c50d48b140d13c123d9b47d9a23c38d12c51d11c3d36b137d12c123d10b47d8a24c38d11c52d11c7d35b134d12c123d10b47d8a24c37d11c54d11c9d37b129d11c124d10b47d8a24c37d11c54d11c12d39b123d12c124d10b47d8a24c37d10c56d10c14b2d40b118d12c125d9b47d8a24c36d11c56d11c18d42b113d11c126d9b47d8a24c36d10c58d10c21d42b110d11c126d9b47d8a24c36d10c58d11c22d43b107d11c126d10b47d7a24c35d11c59d10c25d43b104d10c127d10b47d7a24c35d10c60d11c28d43b99d11c127d10b47d7a24c35d10c61d10c31d43b96d11c128d10b46d7a24c35d10c61d11c33d46b90d11c128d10b46d7a24c35d10c61d11c41d42b86d11c129d9b46d7a24c35d10c61d11c46d41b81d12c129d10b45d7a24c34d11c62d11c49d44b74d12c129d10b45d7a24c34d10c63d11c51d47b68d12c131d9b45d7a24c34d10c64d11c52d50b63d12c131d10b44d7a24c33d11c64d12c52bd51b59d12c132d10b44d7a24c33d11c65d11c54d53b56d12c132d10b44d7a24c32d11c66d11c54d57b51d12c134d9b44d7a24c32d11c67d11c53d61b47d12c134d9b44d7a24c32d10c68d11c51d68b42d11c135d9b44d8a23c31d11c69d11c50d17b2c3b2cd47b37d12c135d9b44d8a23c31d10c70d11c48d19bc11db2d47b30d12c135d10b43d8a23c31d10c71d11c46d20bc12b2c3d49b24d12ec135d10b43d8a23c30d11c71d11c45d21bc20d49b21d13c136d9b43d8a23c30d10c72d11c44d22bc23d51b15d17c133d9b43d8a23c29d11c73d11c41bd24c27d51b10d20c131d9b43d8a23c29d11c73d11c40bd25c31d50b4d24c131d8b43d8a23c28d11c75d11c38bd26c35d75c130d8b43d8a23c28d11c75d11c38d28c35d75c129d8b43d8a23c27d12c76d11c37d29c34d81c123d8b43d8a23c27d12c77d10c34b2d30ec33d13c2d67c122d8b43d8a23c27d11c78d11c33bd32c32d12c9d64c120d9b42d8a23c26d12c78d11c32bd13e2d18c31d13c14d61c118d9b42d8a23c26d12c79d11c31d13e10d12c29bd12c17d61c116d9b41d8a24c26d11c80d12c30d12e12d11c29d13c18d32c4d26c115d8b41d8a24c25d12c81d11c29d12e14d10c29d12c20d11c5d13c8d25c114d8b41d8a24c25d11c83d11bc27d11e15d10c28d13c20d11c27d24c114d9b39d9a24c25d10c84d12c26d11e16d11c27d12c21d11c29d23c113d9b39d9a24c24d11c85d11bc25d10e18d10c25bd13c22d10c31d21c113d9b37d11a24c24d11c85d12bc23d11e18d10c24bd13c23d10c38d15c112d9b35d12a25c23d12c86d12c22d11e19d10c23bd13c24d11c39d13c112d9b33d14a25c23d11c87d12c22d10e21d10c22d13c26d10c40d12c112d9b31d15a26c23d11c88d11c21d11e21d10c22d12c27d10c41d11c111d10b29d17a26c22d11c89d12c20d11e21d10c21d13c27d10c42d11c110d10b25d20a27c22d11c90d11c19d11e22d10c20d13c29d10c41d11c110d10b23d21a28c22d10c91d12c17d12e23d9c20d12c30d10c42d10c110d10b21d21a30c21d11c92d12c16d11e24d10c18d11c32d10c42d10c110d10b18d22a32c21d10c94d11c15d12e24d10c18d10c33d10c42d10c110d10b16d22a34c21d10c94d12c14d11e25d10c17d11c33d10c42d10c110d10b14d22a36c21d10c95d11c13d11e27d9c16d11c35d10c41d10c110d10b11d23a38c21d10c95d12c12d11e27d9c16d11c35d10c41d10c110d10b9d23a40c21d10c24d19c53d12c10d11e28d9c15d12c35d10c41d10c110d11b3d24a44c21d10c12d46c39d11c9d12e28d9c15d12c35d10c41d10c110d36a46c21d12c5d53c37d12c8d12e28d10c13d12c36d10c41d10c110d34a48c21d71c37d12c6d13e28d10c12d13c36d10c41d10c110d31a51c21d72c37d11c5d14e28d10c11d13c38d9c41d10c110d28a54c21d74c35d12c3d15e29d9bc9d13c39d9c41d10c110d26a56c20d76c35d12ced16e28d9bc8d13c40d9c41d11c109d24a58c20d77c34d30e28d10c8d12c41d9c42d10c109d21a61c20d79c33d29e28d10c7d12c42d9c42d10c109d18a64c19d45c9d27c33d28e28d10c6d12c44d8c42d10c109d15a67c19d37c26d20c31d29e26d11c5d12c45d9c41d10c109d11a71c18d27c40d18c31d28e26d11c5d11c46d9c41d10c108d11a72c18d12c56d18c31d28e24d13c3d12c46d9c41d10c107d11a73c17d12c59d18c29d28e24d13c2d12c47d9c41d10c105d13a73c17d11c61d19c28d27e23d28c47d10c40d10c103d16a72c16d11c63d19c28d26e23d27c48d10c40d10c93d6cd18a73c16d11c65d18c27d13c3d11e21d27c49d10c40d10c90d28a73c15d11c67d18c27d12c3d20e11d28c49d10c41d9c88d30a73c15d11c69d17c26d11c4d27e3d28c50d10c41d10c85d31a74c14d12c70d18c25d9c5d57c52d9c41d10c83d32a75c14d11c72d21c22d6c8d55c53d9c41d10c82d32a76c13d12c74d21c34d54c54d9c41d10c79d34a77c13d12c75d21c33d53c55d9c41d10c68d42a80c12d12c77d22c31d52c56d10c40d10c64d40a86c12d12c79d22c28d53c56d10c40d10c62d40a88c11d12c82d22c26d52c57d10c40d10c60d36a94c11d11c85d22c23d40cd11c58d10c40d10c58d35a97c11d11c87d21c22d12e7d20c3d9c59d10c40d10c57d35a98c11d10c89d22c19d12e12d16c4d7c60d10c40d10c54d36a100c10d11c91d21c18d11e16d13c5d5c61d10c40d10c44d44a102c10d10c93d21c16d12e18d11c72d9c40d10c40d45a105c10d10c95d22c13d11e20d10c72d9c39d11c38d42a110c10d10c97d21c11d12e20d10c72d9c39d11c36d36a118c10d10c99d20c10d12e20d11c71d9c39d11c34d35a121c9d11c102d19c7d12e21d11c33d8c30d10c38d10c33d35a123c8d12c103d21c4d12e21d11c31d13c27d10c38d10c31d35a125c8d12c105d34e23d10c30d16c25d10c37d11c29d35a127c7d12c107d32e24d10c28d20c23d10c37d11c26d36a129c7d12c109d30e24d10c27d23c21d10c37d11c19d37a135c6d12c111d28e25d10c25d27c20d9c37d10c15d33a144c6d12c113d25e26d11c18d35c18d9c37d10c13d33a146c5d12c115d24e27d10c16d39c16d9c37d10c10d34a148c5d12c117d21e28d10c14d44c13d9c37d10c8d34a150c5d11c120d19e28d10c9d51c10d10c37d11c4d36a151c4d12c122d17e28d10c7d28c2d25c8d10c37d49a153c4d11c125d14e29d10e2c3d27c8d25c5d10c37d46a156c3d12c127d12e29d11ed29c10d26c3d10c37d43a159c3d11c128d11e30d39c15d35c38d34a168c2d12c128d11e30d36c20d33c38d31a171c2d12c127d11e31d34c25d30c38d29a173cd12c128d11e31d30c31d28c38d27a175d13c127d11e32d28c35d26c38d25a177d12c128d11e32d26c38d25c38d23a179d12c127d12e32d24c42d23c38d21a181d11c128d12e32d18c53d17c39d17a185d10c128d12e33d16c57d15c39d12a190d10c128d11e35d11c63d12c40d11a191d9c129d11e35d10c67d7c42d11a191d9c128d11e36d10c116d10a192d9c128d10e37d10c116d10a192d8c128d11e37d10c115d11a192d8c128d10e38d10c115d11a192d8c127d11e38d10c115d11a192d7c128d10e39d10c115d11a192d7c128d10e39d10c115d11a192d7c127d11e39d10c114d12a192d6c128d10e40d10c114d12a192d6c127d11e40d10c114d12a192d6c127d11e40d10c114d11a193d5c128d10e41d10c113d12a193d5c127d11e41d10c113d11a194d5c127d11e41d10c113d11a194d4c127d11e42d10c112d12a194d4c127d11e42d10c112d12a194d4c127d10e43d10c112d12a194d3c127d11e43d10c111d12a195d3c127d11e43d10c111d12a195d2c128d10e44d10c111d11a196d2c127d11e44d10c111d11a196dc128d11e44d10c111d11a196dc128d10e45d10c110d12a196c128d11e45d10c110d11a197c128d10e46d10c110d11a197c128d10e46d10c110d11a197c127d10e47d9c111d11a197c127d10e47d9c111d10a198c127d10e47d10c110d10a198c126d11e47d10c110d10a198c126d10e48d10c110d10a198c126d10e48d10c111d10a197c125d10e49d10c111d10a197c125d10e49d10c111d10a197c125d10e49d10c110d11a197c124d11e49d10c110d11a197c124d10e50d10c110d11a197c124d10e49d11c110d11a197c124d10e49d11c109d12a197c123d11e49d11c109d12a197c123d10e49d11c110d11a198c123d10e49d11c110d11a198c122d11e49d11c109d12a198c122d11e49d10c110d12a198c122d10e49d11c110d12a198c122d10e49d11c110d11a199c121d11e49d11c109d12a199c121d10e50d10c110d11a200c121d10e50d10c110d11a200c120d11e50d10c109d12a200c120d10e51d9c110d11a201c120d10e51d9c109d12a201c119d11e51d9c109d11a202c119d11e51d9c109d12a201c119d11e51d9c109d11a202c119d10e52d9c109d11a202c118d11e52d9c108d11a203c118d10e53d9c108d11a203c118d10e53d9c108d11a203c117d11e53d9c108d11a203c117d11e53d9c108d11a203c117d10e53d10c108d11a203c116d11e53d10c108d11a203c116d11e53d10c108d11a203c116d10e54d10c108d11a203c115d11e54d10c108d11a203c115d10e54d11c108d11a203c114d11e54d10c109d11a203c114d11e54d10c109d11a203c114d11e53d11c109d11a203c113d12e53d11c109d11a203c113d11e54d10c109d12a203c112d12e54d10c109d12a203c112d11e55d9c110d12a203c112d11e54d10c110d11a204c111d11e55d10c110d11a204c111d11e55d9c110d12a204c110d11e56d9c110d12a204c110d10e57d9c110d12a204c110d10e57d9c109d12a205c109d11e57d9c109d12a205c109d11e57d9c109d12a205c109d10e57d10c108d12a206c108d11e56d11c108d12a206c108d11e56d10c109d12a206c108d10e56d11c108d12a207c107d11e56d11c108d12a207c107d10e56d11c109d12a207c107d10e56d11c109d11a208c107d10e56d11c108d11a209c107d10e56d10c109d11a209c107d9e56d11c109d11a209c106d10e56d11c109d11a209c106d10e56d10c110d11a209c106d10e56d10c110d10a210c105d11e56d10c110d10a210c105d10e57d10c110d10a210c105d10e56d10c111d10a210c104d11e56d10c111d10a210c104d10e57d10c111d10a210c104d10e57d10c111d10a210c104d10e57d10c111d10a210c103d10e57d11c111d10a210c103d10e57d11c111d10a210c102d11e57d10c112d10a210c102d10e58d10c112d10a210c101d11e58d10c112d10a210c101d11e58d10c111d11a210c100d11e59d10c111d11a210c100d11e59d10c111d11a210c99d11e59d10c112d11a210c99d11e59d10c112d11a210c98d12e59d10c111d12a210c98d11e60d10c111d11a211d2c96d11e59d10c112d11a211d4c93d11e60d10c112d11a211d7c90d11e60d10c111d12a211d19c78d10e60d11c111d12a211d22c75d10e60d10c111d12a212d25c72d10e60d10c111d12a212d27c70d9e61d10c111d12a212d29c67d10e61d10c110d12a213d31c65d10e61d9c111d12a213d35c61d10e61d9c111d11a214d39c56d11e61d9c110d12a214d41c54d10e62d9c110d12a214ed42c51d11e61d10c110d11a215c15d31c48d10e62d10c109d12a215c18d30c45d11e62d10c109d12a215c20d31c42d11e62d10c109d11a216c23d39c30d11e63d10c109d11a216c26d39c27d11e63d10c109d11a216c28d39c24d11e63d10c110d10a217c30d40c21d11e63d10c109d11a217c33d39c18d11e63d11c109d11a217c35d40c15d11e63d11c109d11a217c38d43c8d12e62d12c109d11a217c41d59e63d11c110d11a217c44d56e63d11c110d11a217c51d49e62d11c111d11a217c57d43e62d11c111d11a217c59d42e60d11c112d11a217c62d42e57d11c112d11a217c64d46e51d11c112d11a217c67d51e42d11c113d11a217c70d50e40d11c113d11a217c84d39e37d10c113d12a217c86d40e33d11c113d12a217c88d40e31d10c114d12a217c90d44e25d10c113d12a218c92d45e21d10c114d12a218c94d49e15d10c114d12a218c99d52e6d11c114d12a218c106d61c115d12a218c110d57c115d11a219c114d53c115d11a219c117d51c114d11a219c120d50c111d11a220c123d50c108d11a220c126d50c105d10a221c127d54c99d11a221c127d58c95d10a222c127d12c9d50c82d10a222c126d12c12d53c76d11a222c126d11c15d54c73d11a222c126d11c20d51c70d12a222c126d11c25d49c67d12a222c126d11c28d49c64d11a223c126d10c32d58c51d12a223c126d10c35d60c46d12a223c126d10c39d59c43d12a223c126d10c44d56c41d11a224c125d10c60d43c39d12a223c125d10c64d46c31d12a224c125d10c66d50c25d12a224c124d11c68d51c22d11a225c124d11c71d50c20d11a225c124d11c73d50c18d11a225c124d11c77d8c2d38c15d12a225c123d11c92d36c13d12a225c123d11c94d59a225c122d11c98d55a226c122d11c100d53a226c121d12c104d49a226c121d12c111d42a226c121d11c116d38a226c121d11c118d35a227c120d12c121d32a227c120d11c124d29a228c119d12c135d19a227c119d12c138d16a227c118d12c141d15a226c118d12c143d13a226c117d12c145d12a226c117d12c146d12a225c117d11c147d12a225c116d12c148d11a225c116d11c149d12a224c116d11c149d12a224c115d11c150d12a224c115d11c151d11a224c115d11c151d12a223c114d11c152d11a224c114d11c152d12a223c114d11c153d11a223c114d10c154d11a223c114d10c154d12a222c114d10c154d12a222c114d10c154d12a222c114d10c154d12a222c114d10c154d12a222c113d11c155d11a222c113d11c155d11a222c113d11c155d11a222c113d11c155d11a222c112d11c156d11a222c112d11c157d10a222c111d12c157d10a222c111d12c157d10a222c111d11c158d10a222c110d12c158d10a222c110d12c158d11a221c109d12c160d10a221c109d12c160d10a221c108d12c161d11a220c108d12c161d11a220c107d13c161d11a220c107d12c162d11a220c107d12c162d11a220"}
local function make(class,parent,props)local o=Instance.new(class);for k,v in pairs(props)do o[k]=v end;o.Parent=parent;return o end
local function inked(o,thickness,border)make("UIStroke",o,{Name="Ink",Color=outline,Thickness=thickness,LineJoinMode=Enum.LineJoinMode.Round,ApplyStrokeMode=border and Enum.ApplyStrokeMode.Border or Enum.ApplyStrokeMode.Contextual});return o end
local function face(o,enum)pcall(function()o.Font=enum end);return o end
local view=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280,720)
local narrow=view.X<600
local short=view.Y<480
local gui=make("ScreenGui",playerGui,{Name="FrontierLoading",DisplayOrder=50,IgnoreGuiInset=true,ScreenInsets=Enum.ScreenInsets.None,ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling})
pcall(function()gui.ClipToDeviceSafeArea=false end)
pcall(function()gui.SafeAreaCompatibility=Enum.SafeAreaCompatibility.None end)
local cover=make("Frame",gui,{Name="Cover",Size=UDim2.fromScale(1,1),BackgroundColor3=bg,BorderSizePixel=0})
local function safe()
    local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.zero
    local ok,a=pcall(function()return game:GetService("GuiService"):GetInsetArea(Enum.ScreenInsets.DeviceSafeInsets)end)
    if ok and a and a.Max.X>a.Min.X and a.Max.Y>a.Min.Y then return math.max(0,a.Min.X),math.max(0,a.Min.Y),math.max(0,v.X-a.Max.X),math.max(0,v.Y-a.Max.Y)end
    return 0,0,0,0
end
for i=1,23 do make("Frame",cover,{Name="GridV",Position=UDim2.fromScale(i/24,0),Size=UDim2.new(0,1,1,0),BackgroundColor3=line,BackgroundTransparency=.88,BorderSizePixel=0})end
for i=1,11 do make("Frame",cover,{Name="GridH",Position=UDim2.fromScale(0,i/12),Size=UDim2.new(1,0,0,1),BackgroundColor3=line,BackgroundTransparency=.88,BorderSizePixel=0})end
local shade=make("Frame",cover,{Name="Vignette",Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(3,10,26),BorderSizePixel=0})
make("UIGradient",shade,{Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,.25),NumberSequenceKeypoint.new(.5,1),NumberSequenceKeypoint.new(1,.25)}),Rotation=90})
local commander,doodleImage
local function paintDoodle()
    local d=DOODLE;local img=game:GetService("AssetService"):CreateEditableImage({Size=Vector2.new(d.w,d.h)})
    local pixels=buffer.create(d.w*d.h*4);local p=0
    for c,n in string.gmatch(d.pixels,"(%a)(%d*)")do
        local len,k=tonumber(n)or 1,string.byte(c)-97
        if k>0 then local col=d.palette[k];for j=p,p+len-1 do buffer.writeu32(pixels,j*4,col)end end
        p+=len
    end
    img:WritePixelsBuffer(Vector2.zero,Vector2.new(d.w,d.h),pixels);doodleImage=img
    return Content.fromObject(img)
end
pcall(function()
    commander=make("ImageLabel",cover,{Name="Commander",AnchorPoint=Vector2.new(0,1),BackgroundTransparency=1,ImageContent=paintDoodle(),ScaleType=Enum.ScaleType.Fit,ZIndex=2})
end)
local brandSize=narrow and 36 or short and 42 or math.min(84,math.floor(view.X*.062))
local gap=short and 8 or 14
local tapeH,sealH,meterH=short and 24 or 30,short and 26 or 32,short and 44 or 52
local columnH=tapeH+brandSize*2+sealH+meterH+gap*3+6
local column=make("Frame",cover,{Name="Column",AnchorPoint=Vector2.new(.5,.5),Position=UDim2.new(.5,0,.47,0),Size=UDim2.new(1,-32,0,columnH),BackgroundTransparency=1,ZIndex=3})
make("UIListLayout",column,{FillDirection=Enum.FillDirection.Vertical,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,gap),SortOrder=Enum.SortOrder.LayoutOrder})
local function text(name,value,size,color,order,parent)
    return make("TextLabel",parent or column,{Name=name,LayoutOrder=order or 0,Text=value,TextSize=size,TextColor3=color,BackgroundTransparency=1,Size=UDim2.new(1,0,0,size+6),Font=Enum.Font.BuilderSansBold,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=3})
end
local function tape(parent,name,value,size,rotation,order,fill)
    local t=make("TextLabel",parent,{Name=name,LayoutOrder=order or 0,Text=value,TextSize=size,TextColor3=Color3.fromRGB(17,17,17),BackgroundColor3=fill or yellow,BorderSizePixel=0,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,size+10),Rotation=rotation,ZIndex=4})
    make("UIPadding",t,{PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),PaddingTop=UDim.new(0,2)});make("UICorner",t,{CornerRadius=UDim.new(0,6)});inked(t,3,true)
    return t
end
face(tape(column,"Kicker",korean and "슈퍼 커맨더" or "TAKE THE MAP!",short and 13 or 17,-5,1),Enum.Font.LuckiestGuy)
local brandTop=face(inked(text("BrandTop","SUPER",brandSize,yellow,2),math.max(3,math.floor(brandSize*.12))),Enum.Font.LuckiestGuy)
local brand=face(inked(text("Brand","COMMANDER",brandSize,Color3.new(1,1,1),3),math.max(3,math.floor(brandSize*.12))),Enum.Font.LuckiestGuy)
for _,o in ipairs({brandTop,brand})do o.Rotation=-3;o.Size=UDim2.new(1,0,0,brandSize-2)end
local seal=face(tape(column,"Seal","NO PAY-TO-WIN",short and 12 or 15,3,4,paper),Enum.Font.FredokaOne)
local barW=narrow and 260 or short and 260 or 420
local meter=make("Frame",column,{Name="Meter",LayoutOrder=6,Size=UDim2.fromOffset(barW,meterH),BackgroundTransparency=1,ZIndex=3})
local status=face(make("TextLabel",meter,{Name="Status",Text=korean and "작전 본부에 연결하는 중" or "Connecting to command",TextSize=short and 14 or 16,TextColor3=ink,BackgroundTransparency=1,Size=UDim2.new(1,-56,0,20),Font=Enum.Font.BuilderSansBold,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,ZIndex=3}),Enum.Font.FredokaOne)
local percent=face(make("TextLabel",meter,{Name="Percent",Text="0%",TextSize=short and 14 or 16,TextColor3=yellow,BackgroundTransparency=1,AnchorPoint=Vector2.new(1,0),Position=UDim2.fromScale(1,0),Size=UDim2.fromOffset(56,20),Font=Enum.Font.BuilderSansBold,TextXAlignment=Enum.TextXAlignment.Right,ZIndex=3}),Enum.Font.FredokaOne)
local barH=short and 18 or 24
local track=inked(make("Frame",meter,{Name="Track",AnchorPoint=Vector2.new(0,1),Position=UDim2.fromScale(0,1),Size=UDim2.new(1,0,0,barH),BackgroundColor3=Color3.fromRGB(7,23,51),BorderSizePixel=0,ZIndex=3}),3,true)
make("UICorner",track,{CornerRadius=UDim.new(1,0)})
local fill=make("Frame",track,{Name="Fill",Size=UDim2.fromScale(0,1),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,ZIndex=3})
make("UICorner",fill,{CornerRadius=UDim.new(1,0)})
make("UIGradient",fill,{Rotation=90,Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(127,243,230)),ColorSequenceKeypoint.new(.46,Color3.fromRGB(127,243,230)),ColorSequenceKeypoint.new(.5,accent),ColorSequenceKeypoint.new(1,accent)})})
local tips=korean and {
    "도시 1레벨 = 병력 상한 +25K",
    "공격 20%, 나머지는 국경에",
    "병력 상한 가까이 = 충원 ▼",
    "요새 반경 30칸 방어",
    "같은 땅 두 번 탭 = 바로 공격",
} or {
    "City level = troop cap +25K",
    "Attack 20%, the rest guards borders",
    "Near troop cap = refill ▼",
    "Defense Post guards 30 tiles",
    "Tap the same land twice = attack",
}
local tipRow=make("Frame",cover,{Name="Tip",AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,(narrow or short) and -36 or -48),Size=UDim2.new(1,-32,0,26),BackgroundTransparency=1,ZIndex=3})
make("UIListLayout",tipRow,{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10),SortOrder=Enum.SortOrder.LayoutOrder})
face(tape(tipRow,"Chip","TIP",12,-4,1),Enum.Font.LuckiestGuy)
local tipText=face(make("TextLabel",tipRow,{Name="Text",LayoutOrder=2,Text=tips[math.random(1,#tips)],TextSize=(narrow or short) and 13 or 15,TextColor3=muted,BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.X,Size=UDim2.fromOffset(0,20),Font=Enum.Font.BuilderSansMedium,ZIndex=3}),Enum.Font.FredokaOne)
make("TextLabel",cover,{Name="Copyright",Text="© OpenFront and Contributors",TextSize=12,TextColor3=Color3.fromRGB(142,160,187),BackgroundTransparency=1,AnchorPoint=Vector2.new(.5,1),Position=UDim2.new(.5,0,1,(narrow or short) and -12 or -18),Size=UDim2.new(1,-32,0,16),Font=Enum.Font.BuilderSansMedium,TextXAlignment=Enum.TextXAlignment.Center,ZIndex=3})
local function layout(root)
    local c=root and root:FindFirstChild("Cover");if not c then return end
    local col,tip,copy,cmd=c:FindFirstChild("Column"),c:FindFirstChild("Tip"),c:FindFirstChild("Copyright"),c:FindFirstChild("Commander")
    if not col then return end
    local l,t,r,b=safe()
    local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or view
    if v.X<2 or v.Y<2 then v=root.AbsoluteSize end
    local wide=v.X>=600 and v.X>v.Y;local sh=v.Y<480;local tight=not wide or sh
    local bs=not wide and 36 or sh and 42 or math.min(84,math.floor(v.X*.062))
    local g=sh and 8 or 14;local kick,sealS,meterH,barH,label=sh and 13 or 17,sh and 12 or 15,sh and 44 or 52,sh and 18 or 24,sh and 14 or 16
    local x0,x1=l+16,v.X-r-16
    if cmd then
        local ch=math.floor(v.Y*(wide and .84 or .38));local cw=math.floor(ch*DOODLE.w/DOODLE.h)
        cmd.Size=UDim2.fromOffset(cw,ch);cmd.Position=UDim2.new(0,l-math.floor(cw*.08),1,math.floor(ch*.07))
        cmd.ImageTransparency=wide and 0 or .6
        cmd.Visible=root:GetAttribute("RosterShown")~=true
        if wide and cmd.Visible then x0=l+math.floor(cw*.78)end
    end
    local span=math.max(200,x1-x0);local cx=math.floor((x0+x1)/2)
    local list=col:FindFirstChildOfClass("UIListLayout");if list then list.Padding=UDim.new(0,g)end
    local kicker,top,brand,seal,meter=col:FindFirstChild("Kicker"),col:FindFirstChild("BrandTop"),col:FindFirstChild("Brand"),col:FindFirstChild("Seal"),col:FindFirstChild("Meter")
    if kicker then kicker.TextSize=kick;kicker.Size=UDim2.fromOffset(0,kick+10)end
    for _,o in ipairs({top or false,brand or false})do if o then o.TextSize=bs;o.Size=UDim2.new(1,0,0,bs-2);local ink=o:FindFirstChild("Ink");if ink then ink.Thickness=math.max(3,math.floor(bs*.12))end end end
    if seal then seal.TextSize=sealS;seal.Size=UDim2.fromOffset(0,sealS+10)end
    local barW=tight and 260 or 420
    if meter then
        meter.Size=UDim2.fromOffset(barW,meterH)
        for _,n in ipairs({"Status","Percent"})do local o=meter:FindFirstChild(n);if o then o.TextSize=label end end
        local tr=meter:FindFirstChild("Track");if tr then tr.Size=UDim2.new(1,0,0,barH)end
    end
    local h=(kick+10)+(bs-2)*2+(sealS+10)+meterH+g*4+6
    col.Position=UDim2.new(0,cx,.47,math.floor((t-b)/2));col.Size=UDim2.new(0,math.min(span,620),0,h)
    if tip then
        tip.Position=UDim2.new(0,cx,1,(tight and -36 or -48)-b);tip.Size=UDim2.new(0,span,0,tip.Size.Y.Offset)
        local line=tip:FindFirstChild("Text");if line then line.TextSize=tight and 13 or 15 end
    end
    if copy then copy.Position=UDim2.new(0,cx,1,(tight and -12 or -18)-b);copy.Size=UDim2.new(0,span,0,copy.Size.Y.Offset)end
end
local function fit()if gui.Parent and gui:GetAttribute("RosterShown")~=true then layout(gui)end end
fit()
local function watchCamera()local cam=workspace.CurrentCamera;if cam then cam:GetPropertyChangedSignal("ViewportSize"):Connect(fit)end end
watchCamera();workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()watchCamera();fit()end)
gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
gui:GetAttributeChangedSignal("RosterShown"):Connect(function()
    if gui:GetAttribute("RosterShown")==true then if commander then commander.Visible=false end else fit()end
end)
pcall(function()RF:RemoveDefaultLoadingScreen()end)
local hopped=false
pcall(function()
    local TS=game:GetService("TeleportService")
    if TS:GetArrivingTeleportGui()~=nil or TS:GetLocalPlayerTeleportData()~=nil then me:SetAttribute("SuperCommanderHop",true);hopped=true end
    local was=TS:GetArrivingTeleportGui();was=was and was:FindFirstChild("Status",true)
    if was and was:IsA("TextLabel")and was.Text~=""then status.Text=was.Text end
end)
local depart
pcall(function()
    local was=game:GetService("TeleportService"):GetArrivingTeleportGui()
    if was and was.Name=="FrontierDepart"then depart=was:Clone();depart.DisplayOrder=51;depart.Enabled=true;depart.Parent=playerGui end
end)
if depart then task.spawn(function()
    local steps=depart:FindFirstChild("Steps",true);local faces=depart:FindFirstChild("Faces",true)
    local function step(i)return steps and steps:FindFirstChild("Step"..i)end
    local function set(i,p,color)local st=step(i);if not st then return end;st.Track.Fill.Size=UDim2.fromScale(math.clamp(p,0,1),1);if color then st.Label.TextColor3=color end end
    set(1,1,ink);set(2,1,ink);set(3,0,accent)
    local total=0;for _,f in ipairs(faces and faces:GetChildren()or {})do if f:GetAttribute("UserId")then total+=1 end end
    local mapFrom
    while depart.Parent do
        local here=0
        for _,f in ipairs(faces and faces:GetChildren()or {})do local id=f:GetAttribute("UserId")
            if id then local on=Players:GetPlayerByUserId(id)~=nil;if on then here+=1 end
                f.ImageTransparency=on and 0 or .55;local ring=f:FindFirstChild("Ring");if ring then ring.Transparency=on and 0 or .75 end end end
        local s3=step(3);if s3 then local base=s3.Label:GetAttribute("Base")or s3.Label.Text;s3.Label:SetAttribute("Base",base);s3.Label.Text=string.format("%s %d/%d",base,here,math.max(total,here))end
        local ui=playerGui:FindFirstChild("FrontierNativeUI");local building=ui and type(ui:GetAttribute("LoadingMap"))=="string"and ui:GetAttribute("LoadingMap")~=""
        if (total>0 and here>=total)or building then mapFrom=mapFrom or os.clock()end
        if mapFrom then set(3,1,ink);set(4,.2+.75*(1-math.exp(-(os.clock()-mapFrom)/6)),accent)
        else set(3,total>0 and here/total or .5)end
        task.wait(.2)
    end
end)end
pcall(function()
    local hop=gui:Clone();hop.Name="FrontierTeleport";hop.Enabled=false
    local hm=hop.Cover.Column
    hm.Meter.Status.Text=korean and "전선으로 이동하는 중" or "Moving to the front";hm.Meter.Percent.Text="20%"
    hm.Meter.Track.Fill.Size=UDim2.fromScale(.2,1)
    hop.Parent=playerGui
    local pending=false
    local function refit()
        if not hop.Parent or pending then return end
        pending=true
        task.delay(.2,function()
            pending=false;if not hop.Parent then return end
            layout(hop)
            local ride=hop:Clone();ride.Enabled=true
            pcall(function()game:GetService("TeleportService"):SetTeleportGui(ride)end)
        end)
    end
    layout(hop);local ride=hop:Clone();ride.Enabled=true
    game:GetService("TeleportService"):SetTeleportGui(ride)
    gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit);hop:GetPropertyChangedSignal("AbsoluteSize"):Connect(refit)
    hop:GetPropertyChangedSignal("Enabled"):Connect(function()if hop.Enabled then layout(hop)end end)
end)
local alive,target,shown=true,.2,hopped and .2 or 0
local function advance(to,message)target=math.max(target,to);if message then status.Text=message end end
task.spawn(function()
    while alive do
        if shown<target then shown=math.min(target,shown+(target>=1 and .05 or .02))end
        fill.Size=UDim2.fromScale(shown,1);percent.Text=math.floor(shown*100+.5).."%"
        task.wait(.03)
    end
end)
task.spawn(function()
    local i=1
    while alive do task.wait(4.5);if not alive then break end;i=i%#tips+1;tipText.Text=tips[i]end
end)
local started=os.clock()
advance(.35)
if not game:IsLoaded() then game.Loaded:Wait() end
local loadedAt=os.clock()
if commander then pcall(function()
    local content=paintDoodle();commander.ImageContent=content
    local hop=playerGui:FindFirstChild("FrontierTeleport");local c=hop and hop:FindFirstChild("Commander",true);if c then c.ImageContent=content end
end)end
advance(.75,korean and "지휘 화면을 준비하는 중" or "Preparing the war room")
local ui=playerGui:WaitForChild("FrontierNativeUI",math.max(1,25-(os.clock()-started)))
while ui and ui:GetAttribute("Phase")==nil and os.clock()-started<25 do task.wait(.05)end
pcall(function()me:SetAttribute('LoadCoverClocks',string.format('%.3f,%.3f',loadedAt,os.clock()))end)
pcall(function()me:SetAttribute('LoadCoverStages',string.format('%d,%d,%d,%d',math.floor((loadedAt-started)*1000),math.floor((os.clock()-started)*1000),ui and 1 or 0,os.clock()-started>=25 and 1 or 0))end)
task.wait()
if ui and ui:GetAttribute("Loading")==true then
    local held,off=os.clock(),nil
    while ui.Parent and os.clock()-held<90 do
        if ui:GetAttribute("Loading")==true then off=nil elseif not off then off=os.clock()elseif os.clock()-off>=.3 then break end
        local map=ui:GetAttribute("LoadingMap")
        status.Text=(korean and "전장을 준비하는 중" or "Preparing the front")..(type(map)=="string"and map~=""and "  /  "..map or "")
        target=math.max(target,.75+.2*(1-math.exp(-(os.clock()-held)/15)))
        task.wait(.05)
    end
end
advance(1,korean and "출격 준비 완료" or "Ready")
local finishing=os.clock()
while shown<1 and os.clock()-finishing<1 do task.wait(.03)end
gui:SetAttribute("Lifting",true);task.wait()
task.wait(.25)
alive=false
local fade=TweenInfo.new(.35,Enum.EasingStyle.Quad)
for _,o in ipairs(cover:GetDescendants())do
    if o:IsA("TextLabel")then TweenService:Create(o,fade,{TextTransparency=1,BackgroundTransparency=1}):Play()
    elseif o:IsA("ImageLabel")then TweenService:Create(o,fade,{ImageTransparency=1}):Play()
    elseif o:IsA("Frame")then TweenService:Create(o,fade,{BackgroundTransparency=1}):Play()
    elseif o:IsA("UIStroke")then TweenService:Create(o,fade,{Transparency=1}):Play()end
end
TweenService:Create(cover,fade,{BackgroundTransparency=1}):Play()
if depart and depart.Parent then
    for _,o in ipairs(depart:GetDescendants())do
        if o:IsA("TextLabel")then TweenService:Create(o,fade,{TextTransparency=1}):Play()
        elseif o:IsA("ImageLabel")then TweenService:Create(o,fade,{ImageTransparency=1,BackgroundTransparency=1}):Play()
        elseif o:IsA("GuiObject")then TweenService:Create(o,fade,{BackgroundTransparency=1}):Play()
        elseif o:IsA("UIStroke")then TweenService:Create(o,fade,{Transparency=1}):Play()end
    end
end
task.wait(.4)
if depart then depart:Destroy()end
gui:Destroy()
