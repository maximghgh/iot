<template>
    <div v-if="loading" class="loading">Загрузка…</div>

    <div v-else class="container py-5">
        <button @click="goBack" class="btn-back">< Назад</button>
        <h1>{{ chapter.title }}</h1>

        <video
            v-if="chapter.type === 'video' && chapter.video_url"
            :src="chapter.video_url"
            controls
            class="chapter-video"
        />

        <div v-if="hasContent" id="editorjs" class="chapter-content"></div>

        <div v-if="isTask" class="task-block">
            <button @click="showModal = true" class="answer">
                Показать правильный ответ
            </button>
        </div>

        <!-- Модальное окно -->
        <div
            v-if="showModal"
            class="modal-overlay"
            @click.self="showModal = false"
        >
            <div class="modal">
                <button class="modal-close" @click="showModal = false">
                    ×
                </button>
                <h2>Правильный ответ</h2>
                <p>{{ chapter.correct_answer }}</p>
            </div>
        </div>
        <button
            v-if="!chapter.is_completed"
            @click="markChapterCompleted(chapter)"
            class="button button--sub"
        >
            Отметить как пройдено
        </button>
        <div v-else>
            <p>Глава уже пройдена!</p>
        </div>

        <!-- <iframe
            v-if="chapter.presentation_path"
            :src="viewerSrc"
            class="chapter-presentation"
        ></iframe> -->
    </div>
</template>

<script setup>
import { ref, onMounted, computed, nextTick } from "vue"; // если пользуетесь vue-router
import axios from "axios";
import EditorJS from "@editorjs/editorjs";
import Header from "@editorjs/header";
import List from "@editorjs/list";
import ImageTool from "@editorjs/image";

// --- базовый префикс для всех запросов
axios.defaults.baseURL = "/api";

// --- входные данные
const props = defineProps({ initId: Number });

// --- состояние
const chapter = ref({});
const loading = ref(true);
const showModal = ref(false);
let editor = null;

// --- вычисляем id: либо из prop, либо из URL
const chapterId = computed(
    () => window.location.pathname.match(/\/chapter\/(\d+)/)?.[1] || null
);
const isTask = computed(() => chapter.value.type === "task");
// --- helpers
const hasContent = computed(() => !!chapter.value.content);
const isVideo = computed(
    () => chapter.value.type === "video" && !!chapter.value.video_url
);
const hasPresentation = computed(() => !!chapter.value.presentation_path);
const viewerSrc = computed(() =>
    hasPresentation.value
        ? `https://drive.google.com/viewerng/viewer?embedded=true&url=${encodeURIComponent(
              chapter.value.presentation_path
          )}`
        : ""
);

// --- методы
function goBack() {
    window.history.back();
}

async function fetchChapter() {
    if (!chapterId.value) {
        alert("Не удалось определить ID главы");
        return;
    }

    // 1) Сначала забираем данные
    try {
        const { data } = await axios.get(`/chapter/${chapterId.value}`, {
          params: { user_id: storedUser.id }
        });
        chapter.value = data;
    } catch (err) {
        console.error(err);
        alert("Не удалось загрузить главу");
        return;
    }

    // 2) Отмечаем, что загрузка закончилась → Vue вставит контейнер и <div id="editorjs">
    loading.value = false;

    // 3) Только теперь инициализируем EditorJS
    if (hasContent.value) {
        await nextTick(); // ждём, пока DOM-элемент появится
        if (editor) await editor.destroy();

        editor = new EditorJS({
            holder: "editorjs",
            readOnly: true,
            tools: {
                header: Header,
                list: List,
                image: ImageTool,
            },
            data:
                typeof chapter.value.content === "string"
                    ? JSON.parse(chapter.value.content)
                    : chapter.value.content || {},
        });
    }
}
const storedUser = JSON.parse(localStorage.getItem("user"));
async function markChapterCompleted(chapter) {
    if (chapter.is_completed) return;
    try {
        await axios.post(`/chapters/${chapter.id}/complete`, {
            user_id: storedUser.id,
        });

        // 1. Вариант: прямо изменить у выбранной главы
        chapter.is_completed = true;

        // 2. Дополнительно найти эту главу внутри topics.value и проставить is_completed = true,
        //    чтобы, если пользователь переключится между главами, данные были согласованы.
        // topics.value.forEach((topic) => {
        //     topic.chapters.forEach((ch) => {
        //         if (ch.id === chapter.id) {
        //             ch.is_completed = true;
        //         }
        //     });
        // });

        console.log(`Глава ${chapter.id} отмечена как пройденная`);
        console.log("После отметки: is_completed =", chapter.is_completed);
    } catch (error) {
        console.error("Ошибка при завершении главы:", error);
    }
}

onMounted(fetchChapter);
</script>

<style scoped>
.button {
    margin-top: 16px;
    padding: 8px 16px;
    background: #617aff;
    color: #fff;
    border: none;
    cursor: pointer;
    border-radius: 4px;
}
.button--sub {
    background: rgb(56, 184, 56) !important;
}
.modal-overlay {
    position: fixed;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    background-color: rgba(0, 0, 0, 0.5);
    display: flex;
    align-items: center;
    justify-content: center;
}
.modal {
    background: #fff;
    padding: 24px;
    border-radius: 8px;
    max-width: 90%;
    width: 400px;
    position: relative;
}
.modal-close {
    position: absolute;
    top: 8px;
    right: 12px;
    background: none;
    border: none;
    font-size: 20px;
    cursor: pointer;
}
.answer {
    margin-top: 16px;
    padding: 8px 12px;
    background-color: #5b4bff;
    color: white;
    border: none;
    border-radius: 4px;
    cursor: pointer;
}
.container {
    max-width: 800px;
    margin: 40px auto;
    padding: 0 16px;
}
.btn-back {
    background: none;
    border: none;
    color: #5b4bff;
    cursor: pointer;
    margin-bottom: 20px;
}
.chapter-video {
    width: 100%;
    border-radius: 8px;
    margin-bottom: 24px;
}
.chapter-content {
    margin-top: 30px;
    padding: 16px;
    margin-bottom: 24px;
}
.chapter-presentation {
    width: 100%;
    height: 70vh;
    border-radius: 8px;
    margin-bottom: 24px;
}
.loading {
    text-align: center;
    padding: 40px 0;
}
</style>
