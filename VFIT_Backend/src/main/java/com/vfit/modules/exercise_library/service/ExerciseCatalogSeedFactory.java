package com.vfit.modules.exercise_library.service;

import com.vfit.modules.exercise_library.document.ExerciseCatalog;
import java.util.List;
import org.springframework.stereotype.Component;

@Component
public class ExerciseCatalogSeedFactory {
        public static final String DEFAULT_CATALOG_ID = "vfit-default";
        public static final int DEFAULT_VERSION = 4; // Nâng version để tự động override và giải phóng bộ nhớ cache cũ

        public ExerciseCatalog defaultCatalog(String locale) {
                return ExerciseCatalog.builder()
                                .id(DEFAULT_CATALOG_ID)
                                .version(DEFAULT_VERSION)
                                .locale(locale)
                                .active(true)
                                .groups(List.of(
                                                // ==========================================
                                                // 1. TAY SAU (TRICEPS)
                                                // ==========================================
                                                group("triceps", "Tay sau", 10, List.of(
                                                                sub("triceps-general", "Bài tập Tay Sau", 10, List.of(
                                                                                ex("triceps-pushdown",
                                                                                                "Triceps Pushdown",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7640615507942575377?_r=1&_t=ZS-96Scpp2affY",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Đứng hơi nghiêng người nhẹ. Khuỷu tay ghim sát thân. Đẩy thanh/dây xuống đến khi tay gần thẳng. Siết mạnh tay sau ở cuối rep. Thả lên chậm. Lưu ý: Không vung vai hay dùng lực người. Khuỷu tay không di chuyển ra trước sau. Không khóa cứng khuỷu cuối rep. Rope sẽ ăn phần long head tốt hơn bar. Lỗi thường gặp: Dùng tạ quá nặng -> phải đung đưa người. Đẩy bằng vai/ngực thay vì tay sau.",
                                                                                                List.of("cable"),
                                                                                                10),
                                                                                ex("lying-triceps-extensions",
                                                                                                "Lying Triceps Extensions",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7636116644674161921?_r=1&_t=ZS-96Scpp2affY",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Nằm ghế phẳng. Giữ khuỷu cố định. Hạ tạ về gần trán hoặc sau đầu nhẹ. Duỗi tay lên bằng cơ tay sau. Lưu ý: Không flare khuỷu quá rộng. Hạ chậm để tránh áp lực khuỷu. EZ bar thường đỡ đau cổ tay hơn. Mẹo: Hạ hơi ra sau đầu sẽ stretch tay sau nhiều hơn.",
                                                                                                List.of("ez-bar",
                                                                                                                "bench"),
                                                                                                20),
                                                                                ex("overhead-tricep-extension",
                                                                                                "Overhead Tricep Extension",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7627989099143597329?_r=1&_t=ZS-96Scpp2affY",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Giữ tạ phía sau đầu. Khuỷu hướng lên trần. Duỗi tay lên cao bằng cơ tay sau. Lưu ý: Không ưỡn lưng. Khuỷu giữ cố định. Đây là bài stretch long head rất tốt. Lỗi thường gặp: Mở khuỷu quá rộng. Dùng lưng để đẩy tạ.",
                                                                                                List.of("dumbbell",
                                                                                                                "cable"),
                                                                                                30))))),

                                                // ==========================================
                                                // 2. TAY TRƯỚC (BICEPS)
                                                // ==========================================
                                                group("biceps", "Tay trước", 20, List.of(
                                                                sub("biceps-general", "Bài tập Tay Trước", 10, List.of(
                                                                                ex("cable-bayesian-curl",
                                                                                                "Cable Bayesian Curl",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7589457023259954433?_r=1&_t=ZS-96Scpp2affY",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Đứng quay lưng với máy cáp. Tay cầm handle ở phía sau người. Curl lên bằng tay trước. Giữ ngực mở và vai ổn định. Tác dụng: Stretch cực mạnh đầu dài biceps. Rất tốt để tạo peak tay. Lưu ý: Không kéo bằng vai. Không vung người. Duỗi tay có kiểm soát ở cuối rep.",
                                                                                                List.of("cable"),
                                                                                                10),
                                                                                ex("incline-dumbbell-curl",
                                                                                                "Incline Dumbbell Curl",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7618743084087512321?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ghế nghiêng khoảng 45–60 độ. Tay thả tự nhiên ra sau. Curl tạ lên nhưng không nhấc khuỷu. Hạ xuống chậm. Lưu ý: Không swing người. Không dùng vai trước hỗ trợ. Đây là bài stretch biceps rất mạnh nên tập nhẹ kiểm soát. Mẹo: Xoay cổ tay nhẹ (supination) khi lên sẽ ăn biceps hơn.",
                                                                                                List.of("dumbbell",
                                                                                                                "bench"),
                                                                                                20),
                                                                                ex("bicep-curl", "Bicep Curl",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7584196042317466881?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Đứng thẳng. Khuỷu sát thân. Curl lên tới khi siết mạnh tay trước. Hạ xuống chậm hoàn toàn. Lưu ý: Không nhún lưng. Không nâng khuỷu lên quá cao. Full ROM để ăn cơ tốt hơn.",
                                                                                                List.of("dumbbell",
                                                                                                                "barbell"),
                                                                                                30))))),

                                                // ==========================================
                                                // 3. CHÂN (LEGS)
                                                // ==========================================
                                                group("legs", "Chân đùi", 30, List.of(
                                                                sub("legs-general", "Bài tập Toàn diện Chân đùi", 10,
                                                                                List.of(
                                                                                                ex("dumbbell-romanian-deadlift",
                                                                                                                "Dumbbell Romanian Deadlift",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7623180331281042704?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Cách tập: Cầm tạ trước đùi. Gồng core, giữ lưng thẳng. Đẩy hông ra sau. Hạ tạ sát chân đến khi căng đùi sau. Đẩy hông lên để đứng lại. Lưu ý cực quan trọng: Không squat xuống. Chuyển động là \"hip hinge\" (gập hông). Lưng luôn neutral. Tạ đi sát chân. Sai thường gặp: Cong lưng. Hạ quá sâu mất form. Dùng lưng kéo thay vì đẩy hông.",
                                                                                                                List.of("dumbbell"),
                                                                                                                10),
                                                                                                ex("barbell-deadlift",
                                                                                                                "Barbell Deadlift",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7467343059844549894?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Cách tập: Thanh đòn trên giữa bàn chân. Gập hông + chùng gối. Ngực mở, lưng thẳng. Kéo tạ lên sát chân. Đứng thẳng bằng lực chân + hông. Lưu ý: Không giật lưng. Không ngửa cổ quá mức. Gồng bụng trước khi kéo. Mẹo: Nghĩ như đang \"đạp sàn\". Bar path càng thẳng càng tốt.",
                                                                                                                List.of("barbell"),
                                                                                                                20),
                                                                                                ex("barbell-squat",
                                                                                                                "Barbell Squat",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7564125626001575169?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Cách tập: Đặt bar lên trap/rear delt. Chân rộng ngang vai. Hít sâu gồng bụng. Ngồi xuống bằng hông và gối cùng lúc. Đẩy lên bằng midfoot. Lưu ý: Gối đi cùng hướng mũi chân. Không nhấc gót. Không cong lưng dưới. Độ sâu đẹp: Đùi song song sàn hoặc thấp hơn nhẹ.",
                                                                                                                List.of("barbell"),
                                                                                                                30),
                                                                                                ex("smith-squat",
                                                                                                                "Smith Squat",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7620156173517425937?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Ưu điểm: Dễ giữ thăng bằng. Người mới tập dễ cảm cơ hơn. Cách tập: Chân hơi đưa ra trước bar nhẹ. Xuống chậm. Đẩy bằng gót chân. Lưu ý: Không khóa gối mạnh. Đừng đứng quá sát thanh.",
                                                                                                                List.of("smith-machine"),
                                                                                                                40),
                                                                                                ex("leg-press", "Leg Press",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7473171662842645815?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Cách tập: Lưng áp ghế. Hạ xuống có kiểm soát. Đẩy lên bằng gót/midfoot. Vị trí chân: Chân cao -> ăn mông/đùi sau hơn. Chân thấp -> ăn đùi trước hơn.",
                                                                                                                List.of("machine"),
                                                                                                                50),
                                                                                                ex("leg-curl", "Leg Curl",
                                                                                                                "https://www.tiktok.com/@arielyu.fit/video/7476856375822339370?is_from_webapp=1&sender_device=pc",
                                                                                                                "Ariel Yu | TikTok",
                                                                                                                "Ăn vào: Đùi sau. Cách tập: Curl chân về phía mông. Siết mạnh cuối rep. Hạ xuống chậm. Lưu ý: Không giật người. Full ROM để stretch đùi sau tốt nhất.",
                                                                                                                List.of("machine"),
                                                                                                                60),
                                                                                                ex("leg-extension",
                                                                                                                "Leg Extension",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7507771948806475014?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Ăn vào: Đùi trước. Cách tập: Đá chân thẳng lên trước, giữ đỉnh 1s để siết căng đùi. Hạ xuống chậm kìm lực.",
                                                                                                                List.of("machine"),
                                                                                                                70),
                                                                                                ex("smith-machine-for-calves",
                                                                                                                "Smith Machine for Calves",
                                                                                                                "https://www.tiktok.com/@romanestrng/video/7233399941857660187?is_from_webapp=1&sender_device=pc",
                                                                                                                "Romane | TikTok",
                                                                                                                "Ăn vào: Bắp chuối. Cách tập: Đứng bằng mũi chân trên bục. Hạ gót sâu để stretch bắp chuối tối đa. Nhón lên cao nhất có thể. Lưu ý: Không nhún nảy người, tập chậm có kiểm soát.",
                                                                                                                List.of("smith-machine"),
                                                                                                                80))))),

                                                // ==========================================
                                                // 4. NGỰC (CHEST)
                                                // ==========================================
                                                group("chest", "Ngực", 40, List.of(
                                                                sub("mid-chest", "Ngực giữa", 10, List.of(
                                                                                ex("dumbbell-bench-press",
                                                                                                "Dumbbell Bench Press",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7249839401831878418?is_from_webapp=1&sender_device=pc",
                                                                                                "Dumbbell Press | TikTok",
                                                                                                "Cách tập: Nằm ghế phẳng. Gồng vai sau, ép bả vai chắc. Hạ tạ xuống ngang ngực. Đẩy lên theo đường cong nhẹ hướng vào trung tâm. Lưu ý: Không mở rộng khuỷu góc 90 độ hoàn toàn gây chấn thương vai. Giữ góc khuỷu khoảng 45–70 độ đẹp hơn. Không nảy tạ dội ngực. Ưu điểm: ROM sâu hơn đòn tạ.",
                                                                                                List.of("dumbbell",
                                                                                                                "bench"),
                                                                                                10),
                                                                                ex("barbell-bench-press",
                                                                                                "Barbell Bench Press",
                                                                                                "https://www.tiktok.com/@fiteducate/video/7567778140831878418?is_from_webapp=1&sender_device=pc",
                                                                                                "Fit Educate | TikTok",
                                                                                                "Cách tập: Mắt dưới thanh bar. Gồng lưng trên và core. Hạ bar xuống ngực giữa/dưới. Đẩy lên chắc chắn. Vai luôn ép hạ cố định ra sau. Chân đạp chắc xuống sàn. Sai lầm vai nhô lên trước phá form. Video mốc 2: https://www.tiktok.com/@deltabolic/video/7548628092017921281?is_from_webapp=1&sender_device=pc",
                                                                                                List.of("barbell",
                                                                                                                "bench"),
                                                                                                20),
                                                                                ex("cable-chest-fly-mid",
                                                                                                "Cable Chest Fly",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7540072211021860101?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Ăn vào: Cô lập sợi cơ ngực giữa. Cách tập: Ngực mở căng. Kéo hai tay theo quỹ đạo vòng cung trước người. Tưởng tượng động tác ôm thân cây lớn. Không dùng tay sau press tạ. Giữ khuỷu hơi cong cố định. Video mốc 2: https://www.tiktok.com/@deltabolic/video/7577536489513323793?is_from_webapp=1&sender_device=pc",
                                                                                                List.of("cable"),
                                                                                                30),
                                                                                ex("machine-chest-fly",
                                                                                                "Machine Chest Fly",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7614683044384951553?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Ưu điểm: Khóa chuyển động ổn định, cực an toàn để siết cơ đỉnh ngực giữa. Lưu ý: Điều chỉnh ghế để tay đi ngang ngực.",
                                                                                                List.of("machine"),
                                                                                                40))),
                                                                sub("upper-chest", "Ngực trên", 20, List.of(
                                                                                ex("barbell-incline-bench-press",
                                                                                                "Barbell Incline Bench Press",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7537096458382708024?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ghế nghiêng khoảng 15–30 độ. Hạ thanh đòn xuống thềm ngực trên. Đẩy dứt khoát lên trên. Lưu ý: Không chỉnh dốc quá cao sẽ ăn vào vai trước. Giữ bả vai khóa chặt. Video mốc 2: https://www.tiktok.com/@ea497009qj2/video/7545137332740001046?is_from_webapp=1&sender_device=pc",
                                                                                                List.of("barbell",
                                                                                                                "bench"),
                                                                                                10),
                                                                                ex("dumbbell-incline-bench-press",
                                                                                                "Dumbbell Incline Bench Press",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7616907152652782849?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ghế dốc 30 độ. Hạ tạ đôi sâu kiểm soát để kéo giãn sợi ngực trên thắt vào xương đòn. Đẩy lên hội tụ lực.",
                                                                                                List.of("dumbbell",
                                                                                                                "bench"),
                                                                                                20),
                                                                                ex("cable-low-chest-fly",
                                                                                                "Cable Low Chest Fly",
                                                                                                "https://www.tiktok.com/search?q=Cable%20low%20chest%20fly",
                                                                                                "Tìm 'Cable low chest fly' trên TikTok",
                                                                                                "Cách tập: Kéo cáp từ vị trí ròng rọc thấp lên cao chéo góc. Điểm hội tụ tay ở trước mặt tầng ngực trên. Tập trung cảm nhận đường rãnh cơ ngực trên.",
                                                                                                List.of("cable"),
                                                                                                30))),
                                                                sub("lower-chest", "Ngực dưới", 30, List.of(
                                                                                ex("cable-chest-fly-lower",
                                                                                                "Cable Chest Fly (High-to-Low)",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7554529864800374017?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Đặt ròng rọc cao. Kéo cáp chúc xuống hướng bụng dưới để vát cạnh viền cơ ngực dưới. Tránh gù lưng rụt cổ. Video mốc 2: https://www.tiktok.com/@techniquecoach/video/7425989829940350226?is_from_webapp=1&sender_device=pc. Video mốc 3: https://www.tiktok.com/@jongkeun.gil/video/7506837453756583176?is_from_webapp=1&sender_device=pc",
                                                                                                List.of("cable"),
                                                                                                10),
                                                                                ex("dip", "DIP (Xà kép)",
                                                                                                "https://www.tiktok.com/@hazzytrainer/video/7471157615012121911?is_from_webapp=1&sender_device=pc",
                                                                                                "Hazzy Trainer | TikTok",
                                                                                                "Muốn tập trung vào NGỰC: Hơi chồm người về phía trước, cùi chỏ hơi mở nhẹ sang bên, xuống sâu kéo giãn cạnh ngực dưới. Nếu giữ người thẳng đứng đứng sẽ ăn nhiều vào tay sau.",
                                                                                                List.of("bodyweight"),
                                                                                                20))))),

                                                // ==========================================
                                                // 5. LƯNG (BACK)
                                                // ==========================================
                                                group("back", "Lưng xô", 50, List.of(
                                                                sub("lat", "Lat (Cơ xô)", 10, List.of(
                                                                                ex("lat-pulldown", "Lat Pulldown",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7466985819690044678?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ngực mở nhẹ hướng lên. Kéo thanh đòn xuống thềm ngực trên. Tập trung kéo bằng cùi chỏ hướng ra sau lưng dưới. Hạ chậm kiểm soát lực kháng của xô. Tránh đung đưa người lấy đà.",
                                                                                                List.of("cable", "machine"),
                                                                                                10),
                                                                                ex("pull-up", "Pull Up (Hít xà)",
                                                                                                "https://www.tiktok.com/@gymvibesdaily3/video/7566545698439679254?is_from_webapp=1&sender_device=pc",
                                                                                                "Gym Vibes | TikTok",
                                                                                                "Cách tập: Treo người tự nhiên rộng hơn vai. Phát lực từ cơ xô kéo ngực chạm xà. Giữ vững thân dưới ổn định không đung đưa chân.",
                                                                                                List.of("bodyweight"),
                                                                                                20),
                                                                                ex("dumbbell-row", "Dumbbell Row",
                                                                                                "https://www.tiktok.com/@anhsonn_fitness/video/7489684577447955717?is_from_webapp=1&sender_device=pc",
                                                                                                "Anh Sơn Fitness | TikTok",
                                                                                                "Cách tập: Một tay một gối tựa ghế. Cầm tạ kéo cùi chỏ men sát sườn về hướng hông để bo tròn phần xô dưới. Tránh kéo tạ vế hướng ngực phá form.",
                                                                                                List.of("dumbbell",
                                                                                                                "bench"),
                                                                                                30),
                                                                                ex("cable-straight-arm-lat-pullover",
                                                                                                "Cable Straight-Arm Lat Pullover",
                                                                                                "https://www.tiktok.com/@anhsonn_fitness/video/7535466034904550664?is_from_webapp=1&sender_device=pc",
                                                                                                "Anh Sơn Fitness | TikTok",
                                                                                                "Cách tập: Tay giữ gần thẳng cố định khớp khuỷu. Đè cáp theo đường cong lớn từ trên cao xuống chạm đùi. Bài cô lập xô kéo giãn biên độ tối đa cực tốt.",
                                                                                                List.of("cable"),
                                                                                                40))),
                                                                sub("mid-back", "Lưng giữa & Độ dày", 20, List.of(
                                                                                ex("seated-cable-row",
                                                                                                "Seated Cable Row",
                                                                                                "https://www.tiktok.com/@giakhanhfitness/video/7520786419044928775?is_from_webapp=1&sender_device=pc",
                                                                                                "Gia Khánh Fitness | TikTok",
                                                                                                "Cách tập: Ngồi thẳng lưng, chân đạp chắc bục cố định hông. Kéo tay cầm máy cáp sát sườn hướng về vùng rốn bụng dưới. Siết chặt hai lá bả vai ở điểm cuối hành trình để kiến tạo độ dày lưng giữa.",
                                                                                                List.of("cable", "machine"),
                                                                                                10),
                                                                                ex("barbell-row", "Barbell Row",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7492201739781737783?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Cúi gập người góc 45 độ. Khóa chặt thắt lưng dưới. Phát lực kéo thanh đòn chạm rốn bụng dưới. Lỗi thường gặp: Dùng quán tính nhún đẩy hông hoặc gù cong cột sống thắt lưng rất nguy hiểm.",
                                                                                                List.of("barbell"),
                                                                                                20))),
                                                                sub("low-back", "Lưng dưới", 30, List.of(
                                                                                ex("deadlift", "Deadlift (Posterior Chain)",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7467343059844549894?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Bài tập đại cương phát triển thắt lưng dưới, mông và đùi sau. Yêu cầu giữ cột sống neutral thẳng tuyệt đối suốt hành trình đạp nâng tạ khỏi mặt sàn.",
                                                                                                List.of("barbell"),
                                                                                                10))),
                                                                sub("rear-delt-upper-back", "Lưng trên & Vai sau", 40,
                                                                                List.of(
                                                                                                ex("facepull-back",
                                                                                                                "Facepull (Upper back Focus)",
                                                                                                                "https://www.tiktok.com/@deltabolic/video/7603951007076191489?is_from_webapp=1&sender_device=pc",
                                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                                "Cách tập: Điều chỉnh cáp ngang mặt. Kéo dây thừng về phía trán, mở rộng hai đầu dây sang bên tai để ép chặt cơ vai sau, cơ trám và lưng trên.",
                                                                                                                List.of("cable"),
                                                                                                                10))))),

                                                // ==========================================
                                                // 6. VAI (SHOULDERS)
                                                // ==========================================
                                                group("shoulders", "Cơ vai", 60, List.of(
                                                                sub("front-delt", "Vai trước", 10, List.of(
                                                                                ex("machine-shoulder-press",
                                                                                                "Machine Shoulder Press",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7508183379255233848?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ngồi áp sát lưng vào ghế tựa. Đẩy thẳng tay máy lên cao, không khóa khớp cùi chỏ mạnh ở đỉnh. Hạ chậm kiểm soát lực vai trước.",
                                                                                                List.of("machine"),
                                                                                                10),
                                                                                ex("arnold-dumbbell-shoulder-press",
                                                                                                "Arnold Dumbbell Shoulder Press",
                                                                                                "https://www.tiktok.com/@salarfit_gh/video/7443842385408314642?is_from_webapp=1&sender_device=pc",
                                                                                                "Salar Fit | TikTok",
                                                                                                "Động tác độc quyền của Arnold: Khởi đầu lòng bàn tay hướng vào mặt ngực, trong quá trình press đẩy lên cao tiến hành xoay lật khớp cổ tay hướng ra ngoài.",
                                                                                                List.of("dumbbell"),
                                                                                                20),
                                                                                ex("dumbbell-shoulder-press",
                                                                                                "Dumbbell Shoulder Press",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7460671234355891462?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Ngồi ghế thẳng đứng, đẩy tạ đôi qua đầu. Giữ góc cùi chỏ hơi khép hướng về trước khoảng 15 độ để giảm áp lực xoay bao khớp vai.",
                                                                                                List.of("dumbbell",
                                                                                                                "bench"),
                                                                                                30),
                                                                                ex("cable-front-raise",
                                                                                                "Cable Front Raise",
                                                                                                "https://www.tiktok.com/@arielyu.fit/video/7531393236032654647?is_from_webapp=1&sender_device=pc",
                                                                                                "Ariel Yu | TikTok",
                                                                                                "Cách tập: Đứng thẳng, kéo dây cáp từ dưới lên trước mặt đến khi tay song song sàn. Bài tập cô lập hoàn hảo bó cơ vai trước.",
                                                                                                List.of("cable"),
                                                                                                40))),
                                                                sub("side-delt", "Vai giữa (Tạo độ rộng)", 20, List.of(
                                                                                ex("dumbbell-lateral-raise",
                                                                                                "Dumbbell Lateral Raise",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7486685939025054981?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Người hơi đổ nhẹ về trước 5 độ. Phát lực quăng khuỷu tay sang hai bên rìa ngoài cơ thể để kích hoạt vai giữa. Tránh nhún cầu vai (trap shrug).",
                                                                                                List.of("dumbbell"),
                                                                                                10),
                                                                                ex("cable-shoulder-raise",
                                                                                                "Cable Shoulder Raise",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7486685939025054981?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Kéo cáp một tay sang ngang thân. Tension liên tục từ dây cáp giúp tối ưu hóa sợi cơ vai giữa cực tốt mà tạ đôi không làm được ở đáy ROM.",
                                                                                                List.of("cable"),
                                                                                                20),
                                                                                ex("barbell-upright-row",
                                                                                                "Barbell Upright Row",
                                                                                                "https://www.tiktok.com/@huypt.phuquoc/video/7611912077254331655?is_from_webapp=1&sender_device=pc",
                                                                                                "Huy PT | TikTok",
                                                                                                "Cách tập: Cầm đòn rộng hơn vai nhẹ, kéo thanh đòn dọc sát cơ thể lên đến thềm ngực, cùi chỏ luôn dẫn trước cao hơn bàn tay. Tránh tập tạ quá nặng gây bó khớp vai.",
                                                                                                List.of("barbell"),
                                                                                                30))),
                                                                sub("rear-delt", "Vai sau (Tròn vai)", 30, List.of(
                                                                                ex("reverse-fly",
                                                                                                "Reverse Fly (Machine)",
                                                                                                "https://www.tiktok.com/@gaininthai/video/7478261857011256594?is_from_webapp=1&sender_device=pc",
                                                                                                "Gai | TikTok",
                                                                                                "Cách tập: Ngồi quay ngực áp sát ghế máy Pec Deck. Mở rộng cánh tay ép ra sau, dùng lực hoàn toàn từ bó cơ vai sau.",
                                                                                                List.of("machine"),
                                                                                                10),
                                                                                ex("facepull-shoulders",
                                                                                                "Facepull (Rear Delt)",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7603951007076191489?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Bài tập xây dựng độ dày vai sau và cân bằng hệ vận động cơ bả vai bọc xoay phía sau.",
                                                                                                List.of("cable"),
                                                                                                20),
                                                                                ex("dumbbell-one-arm-reverse-fly",
                                                                                                "Dumbbell One Arm Reverse Fly",
                                                                                                "https://www.tiktok.com/@min41203567/video/7562878773268352276?is_from_webapp=1&sender_device=pc",
                                                                                                "Min | TikTok",
                                                                                                "Cách tập: Cúi người gập hông sâu, một tay bám bục cố định, tay còn lại cầm tạ đôi dang rộng ngang hướng lên trần nhà.",
                                                                                                List.of("dumbbell"),
                                                                                                30),
                                                                                ex("rear-delt-fly", "Rear Delt Fly",
                                                                                                "https://www.tiktok.com/@joinyoucan/video/7582943631053573431?is_from_webapp=1&sender_device=pc",
                                                                                                "YouCan | TikTok",
                                                                                                "Kéo cáp chéo chập tay từ trước ra sau (mốc từ giây 14 trong clip) để cô lập tối đa vùng deltoid sau.",
                                                                                                List.of("cable"),
                                                                                                40))))),

                                                // ==========================================
                                                // 7. BỤNG & TIM MẠCH (CORE & CARDIO)
                                                // ==========================================
                                                group("core-cardio", "Bụng & Cardio", 70, List.of(
                                                                sub("abdominals", "Cơ bụng & Liên sườn", 10, List.of(
                                                                                ex("cable-crunch", "Cable Crunch",
                                                                                                "https://www.tiktok.com/@deltabolic/video/7437651792072117560?is_from_webapp=1&sender_device=pc",
                                                                                                "DeltaBolic (@deltabolic) | TikTok",
                                                                                                "Cách tập: Quỳ trước máy kéo cáp. Giữ dây rope sau đầu. Gập người bằng cơ bụng, không kéo bằng tay. Thở ra khi gập xuống. Lưu ý: Không dùng lưng kéo. Xuống chậm để bụng ăn hơn.",
                                                                                                List.of("cable"),
                                                                                                10))),
                                                                sub("conditioning", "Tim mạch / Đốt mỡ", 20, List.of(
                                                                                ex("incline-walking", "Incline Walking",
                                                                                                "https://www.tiktok.com/search?q=incline%20walking%20treadmill%20fat%20loss",
                                                                                                "Tìm 'incline walking treadmill fat loss' trên TikTok",
                                                                                                "Đi bộ dốc trên máy chạy bộ từ 30-45 phút giúp tối ưu hóa vùng đốt mỡ (Fat-burn zone) và bảo vệ an toàn cho hệ khớp gối.",
                                                                                                List.of("treadmill"),
                                                                                                10)))))))
                                .build();
        }

        private ExerciseCatalog.MuscleGroup group(String slug, String name, int sortOrder,
                        List<ExerciseCatalog.SubMuscleGroup> subGroups) {
                return ExerciseCatalog.MuscleGroup.builder()
                                .slug(slug)
                                .name(name)
                                .sortOrder(sortOrder)
                                .subGroups(subGroups)
                                .build();
        }

        private ExerciseCatalog.SubMuscleGroup sub(String slug, String name, int sortOrder,
                        List<ExerciseCatalog.ExerciseItem> exercises) {
                return ExerciseCatalog.SubMuscleGroup.builder()
                                .slug(slug)
                                .name(name)
                                .sortOrder(sortOrder)
                                .exercises(exercises)
                                .build();
        }

        private ExerciseCatalog.ExerciseItem ex(
                        String id,
                        String name,
                        String videoUrl,
                        String videoSearchHint,
                        String description,
                        List<String> equipment,
                        int sortOrder) {
                return ExerciseCatalog.ExerciseItem.builder()
                                .id(id)
                                .name(name)
                                .videoUrl(videoUrl)
                                .videoSearchHint(videoSearchHint)
                                .description(description)
                                .equipment(equipment)
                                .sortOrder(sortOrder)
                                .active(true)
                                .build();
        }
}