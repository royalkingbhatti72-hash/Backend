export interface TaskDatasetItem {
  task_id: number;
  type: string;
  url: string;
  commission: number;
  credit_points: number;
  is_prepaid: boolean;
  prepaid_value?: number;
}

export interface LevelDatasetItem {
  level: number;
  title: string;
  total_tasks: number;
  level_reward: number;
  total_credit_points: number;
  tasks: TaskDatasetItem[];
}

export function cleanUrl(rawUrl: string): string {
  const match = rawUrl.match(/https?:\/\/[^\s\)\_\]]+/);
  return match ? match[0] : rawUrl.trim();
}

export const DATASET_10_LEVELS: LevelDatasetItem[] = [
  {
    "level": 1,
    "title": "Study",
    "total_tasks": 10,
    "level_reward": 500,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/vo4pMVb0R6M?si=I1idXSAT49o8qQlA", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/00jbG_cfGuQ?si=koLvGK8-Yk-1XBbv", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/Yocja_N5s1I?si=9jvSeT6wfULOpTBX", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/B3u4EFTwprM?si=Yklgf1smjHpY-rbh", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/FrlJl2UXRU0?si=un0Uee3RG2nIciDe", "commission": 80, "credit_points": 30, "is_prepaid": true, "prepaid_value": 1000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/9t5NOKVUTZo?si=rD4k5-dQY4icij07", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/tZ7lsQV95yo?si=KGD7uqw1px-uC8Fb", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/I6O_v-cYh20?si=g4enNZAw5GCqKWb", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/_phJIm8mUT8?si=NYby4z78otMFxM9", "commission": 40, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/JSXlT_xvLko?si=su6ypDXlUoKtPUbT", "commission": 80, "credit_points": 30, "is_prepaid": true, "prepaid_value": 3500 }
    ]
  },
  {
    "level": 2,
    "title": "Vlog",
    "total_tasks": 10,
    "level_reward": 1000,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/nzciqaNN4I0?si=QcGDCUl8ABo9Qlwd", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/1iJE8Lyvvls?si=yP3qFuihCpIdC5UV", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/wyBimQmMZMo?si=BM6sLmxsw3UiQetL", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/798f3txy4Zs?si=NpAZSSjCHf5sXQHn", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/M2iHz1cVKxc?si=AKicqraZOjPv3mgg", "commission": 120, "credit_points": 30, "is_prepaid": true, "prepaid_value": 5500 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/3cZ_QsA-Q0Q?si=EVMDukq8QHPDKnep", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/HGX31br5XD4?si=i55C748M-mSi0lts", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/pgn8wq-WRN8?si=EcwXdqRmVC9LynqC", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/UlvuMvKkg5U?si=O35IJAiVVAKTmttz", "commission": 60, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/K8Y2V9AwOos?si=SxysGiMzNJ9Eg2id", "commission": 120, "credit_points": 30, "is_prepaid": true, "prepaid_value": 9500 }
    ]
  },
  {
    "level": 3,
    "title": "Vlog",
    "total_tasks": 10,
    "level_reward": 1500,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/7vOkn4m-XCs?si=t75KaK78GG1D87ev", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/96GXqWaQcEE?si=QGeuAtrOng32KBf2", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/CZvYvUGLNMg?si=CAdnkQ9DrlGLeNji", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/APe0TO49E00?si=uzr2jUeVwfwiCEpC", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/hbHILEt52VI?si=M-5ga8nGEDax316y", "commission": 160, "credit_points": 30, "is_prepaid": true, "prepaid_value": 15000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/WkQrMzwqKv4?si=_eQzhwDMoiCrsDUi", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/CQpxJhN16pM?si=Huj0tEOmziuHzY-A", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/CBhRIsc_14A?si=taf3RX_E_M3_wgXs", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/F7sPLM-ThnA?si=GozFZ1wHIl4HPnSL", "commission": 80, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/8T0m8f44Kgs?si=XPXvxc3B5IOOXrP-", "commission": 160, "credit_points": 30, "is_prepaid": true, "prepaid_value": 23000 }
    ]
  },
  {
    "level": 4,
    "title": "Vlog",
    "total_tasks": 10,
    "level_reward": 2000,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/ew__gmVo3Nk?si=cFdkl1FDuMSy2749", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/YCzRPKRAWmw?si=OKAr0OUB0T9XBzhJ", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/irHIeMEP5hw?si=Fh8SSfl0koXUrYrk", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/45GUatkxX3s?si=ZjsYNezm1YpflOOJ", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/_PB8D_W6CK8?si=LpdY4Z4-d5CwjcKe", "commission": 200, "credit_points": 30, "is_prepaid": true, "prepaid_value": 35000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/ZnmU_6BD0pY?si=XlE3zCfn8ufLolJ8", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/jCPcZUifbkc?si=W8SFeXKJEnh6h_BT", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/EYeG5TiE2B0?si=IdoR0rcI430rFiXP", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/veNdcvpCNRM?si=LTwSsN-0YCpuY4he", "commission": 100, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/bA1j3q0Q5wo?si=IpB8KdfE9f7NA-_A", "commission": 200, "credit_points": 30, "is_prepaid": true, "prepaid_value": 50000 }
    ]
  },
  {
    "level": 5,
    "title": "Level 5",
    "total_tasks": 10,
    "level_reward": 2500,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/bmyXHQQctyQ?si=WE3n94_t2VjUipve", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/XgnSxvUiXO0?si=22ktWXjGWh1OOnwt", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/pmjH9erWu48?si=ZPVv0sGjxwpdQ2JW", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/HOWaPR9brOE?si=q508JZyHn6ROxrB0", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/yqH3DcxB6Dk?si=kjp1orUfY-WKbbJS", "commission": 300, "credit_points": 30, "is_prepaid": true, "prepaid_value": 62500 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/31HJbpU2RpU?si=y--XuUEVnQumEdqj", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/GwifegtMmUI?si=eP2xJ1bdsoVzTyzY", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/6Ct2D12cHqw?si=_hE-crwndkoC1pBS", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/-6kARhVxEWA?si=dB6y1GiHnaEJBRkC", "commission": 150, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/yIjjg5_5Cxw?si=jD2O34ChfbY65zqA", "commission": 300, "credit_points": 30, "is_prepaid": true, "prepaid_value": 80000 }
    ]
  },
  {
    "level": 6,
    "title": "Level 6",
    "total_tasks": 15,
    "level_reward": 5000,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/qgz-ydhRs4s?si=Il542hKwwSHMMFT3", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/XaEkHoMtc5Q?si=h0RzVrtAK9jQBRcg", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/3nYntR_BmD0?si=OqMoHNGPDd8x4853", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/8BOnFKojVYc?si=59knG1PQVKYd6gVk", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/B3j7o3RfBVI?si=nSo3Ii77SdDR4iI4", "commission": 400, "credit_points": 13, "is_prepaid": true, "prepaid_value": 100000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/TYWrS9lbHVo?si=vylP_TFVidoIjhWL", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/Jjpfl2hgN5k?si=XhKzdxX-i616kqTs", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/t1y9vFl3LQc?si=H-TnYfPxFjrPx91H", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/esY3mHyDFi4?si=3hxcM_soqfG8GTro", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/1lCZKskfCqI?si=GiRq7gaiCzepy0ka", "commission": 400, "credit_points": 13, "is_prepaid": true, "prepaid_value": 130000 },
      { "task_id": 11, "type": "Subscribe", "url": "https://youtu.be/2G34ILUfSPg?si=kAQkhhfMnBzMUxgM", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 12, "type": "Like and Comment", "url": "https://youtu.be/kSeHcwfE6VQ?si=-0ADsQw_4_syKx9L", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 13, "type": "Watch Video (30s)", "url": "https://youtu.be/L-uUzPvBqd8?si=jUhVHtx89nY8_nnY", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 14, "type": "Watch Video (45s)", "url": "https://youtu.be/Cek3y8wZNd8?si=wAfx4TWuvGd4KYcX", "commission": 200, "credit_points": 5, "is_prepaid": false },
      { "task_id": 15, "type": "Prepaid Task #3", "url": "https://youtu.be/neKBxcwqsU4?si=whNCyFEItWErsb7t", "commission": 400, "credit_points": 14, "is_prepaid": true, "prepaid_value": 158000 }
    ]
  },
  {
    "level": 7,
    "title": "Level 7",
    "total_tasks": 15,
    "level_reward": 7500,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/B9WFwGvMUZg?si=0iEB2lrtL56J4cmx", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/YqedmavuG64?si=prGU4MJUaaDCnoBI", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/bA33aA83DUs?si=oOEtJwbWRdtsXZIe", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/l0EC6dvS89M?si=WlG698OLMa_adZkK", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/SJYdo3ScJDM?si=rofNESmY3HHZDE9d", "commission": 500, "credit_points": 13, "is_prepaid": true, "prepaid_value": 180000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/nsV-B79x33I?si=aLI7nHiMwgl0yG1i", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/fCDVn0Ri2dU?si=MmFVxtjmJalzqsSQ", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/4z1OyqDyR2E?si=C0Qc5ZF84_vS-EtS", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/sSFYNRoo4r4?si=6hWH6qxt9ylI7pWi", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/Wr5X3lJ30R4?si=KHX-cBl50XRgR3D1", "commission": 500, "credit_points": 13, "is_prepaid": true, "prepaid_value": 250000 },
      { "task_id": 11, "type": "Subscribe", "url": "https://youtu.be/g_AZ0YMrdqA?si=3F11mD6oKWNZ0iZS", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 12, "type": "Like and Comment", "url": "https://youtu.be/z5X413CeFvk?si=Wy-DnuFa7Hst6mt3", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 13, "type": "Watch Video (30s)", "url": "https://youtu.be/xum7JzyS6e8?si=EcDLPRZ13apIuVAX", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 14, "type": "Watch Video (45s)", "url": "https://youtu.be/5PPwEg1kDRE?si=NWUo_uBJcUAp7FXi", "commission": 250, "credit_points": 5, "is_prepaid": false },
      { "task_id": 15, "type": "Prepaid Task #3", "url": "https://youtu.be/fHDijn2Il8E?si=s42SIQM3iiylVKBG", "commission": 500, "credit_points": 14, "is_prepaid": true, "prepaid_value": 330000 }
    ]
  },
  {
    "level": 8,
    "title": "Level 8",
    "total_tasks": 15,
    "level_reward": 10000,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/OS-WTughD14?si=xyiP5FPupBzSfQ9p", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/d4M3YRLiSwM?si=D0a3oKwRCFUdkJ5B", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/nGNlcnGobAY?si=nK83aH5a-W8ph9Xv", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/hTkjqhOsgwc?si=QGKy8vK_l7vLut11", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/AGUb2Nn7pKQ?si=-3czbIuznEgR0tew", "commission": 600, "credit_points": 13, "is_prepaid": true, "prepaid_value": 350000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/h76Q3E_9aNw?si=l3FGEQYqwFooHtvF", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/m7pxtU5qz2U?si=QoDpPdbZNjePMXMb", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/7bGRQJzAKZw?si=uwF3CcleRr4o30up", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/5Z-qAutLgHA?si=GyPFMacS3gxvVogE", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/0TCQClBCJA8?si=S9dn0asC5H9fRU8p", "commission": 600, "credit_points": 13, "is_prepaid": true, "prepaid_value": 452000 },
      { "task_id": 11, "type": "Subscribe", "url": "https://youtu.be/WQ3ilqvjWkA?si=_qrBM_NbqwQ59mE6", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 12, "type": "Like and Comment", "url": "https://youtu.be/Y_UNYQfM4gc?si=rPviVuTWzMIP-uhO", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 13, "type": "Watch Video (30s)", "url": "https://youtu.be/ALEEcf3P2ik?si=lPeca_AjIgaEm_4B", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 14, "type": "Watch Video (45s)", "url": "https://youtu.be/ah8c4GSOdIE?si=N3lHphBCuhG1wdrR", "commission": 300, "credit_points": 5, "is_prepaid": false },
      { "task_id": 15, "type": "Prepaid Task #3", "url": "https://youtu.be/hA9a9ZSj3zY?si=704_2oZyvqFqQsSH", "commission": 600, "credit_points": 14, "is_prepaid": true, "prepaid_value": 550000 }
    ]
  },
  {
    "level": 9,
    "title": "Level 9",
    "total_tasks": 20,
    "level_reward": 12500,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/AnYl6Nk9GOA?si=uJMUmAkCoFVqzSZ2", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/UItWltVZZmE?si=4fMmgvmTZhm9xq9s", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/Cw-Wt4xKD2s?si=HCCHU3lcQEGIOpAV", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/jC5xlKIQgR8?si=SM5t6XKxplYQIXlP", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/X8FNAzCoCoI?si=VLs5Ol5Gh2StDnzK", "commission": 800, "credit_points": 9, "is_prepaid": true, "prepaid_value": 600000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/fsJ14Bra8Io?si=Q2E7TZ-Gi0s6Eu7A", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/4tQrUif5pHY?si=qkw8NRq_gj0mmJMW", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/Nw5rO-fmL0A?si=JzoRZ80tEG6itSRk", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/EtjXNMS3eeU?si=kxWkl392jatI2qT6", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/UV63-EXSFI8?si=amwqxlSS2QF08epH", "commission": 800, "credit_points": 9, "is_prepaid": true, "prepaid_value": 700000 },
      { "task_id": 11, "type": "Subscribe", "url": "https://youtu.be/oNGDopPcghA?si=N87jtZd0fqhR6sqM", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 12, "type": "Like and Comment", "url": "https://youtu.be/k_NZOTYGJhY?si=sBGO9CtwPDDSgS17", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 13, "type": "Watch Video (30s)", "url": "https://youtu.be/M2vs_zjIbOw?si=_vOS90oPdeTVnZ2w", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 14, "type": "Watch Video (45s)", "url": "https://youtu.be/-4E9tAH7cfU?si=2Al-wYIi-diJ-BlS", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 15, "type": "Prepaid Task #3", "url": "https://youtu.be/tlxJv2cdlAU?si=a1g4vUtwS8Lj_m2S", "commission": 800, "credit_points": 9, "is_prepaid": true, "prepaid_value": 850000 },
      { "task_id": 16, "type": "Subscribe", "url": "https://youtu.be/DLGqHOMIE5c?si=f4XCCwwkd0hwxnOL", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 17, "type": "Like and Comment", "url": "https://youtu.be/gjV-K4g3fm4?si=n_5RYC2-NM19_VhH", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 18, "type": "Watch Video (30s)", "url": "https://youtu.be/LhUkk8z5V5E?si=yJjzGjtCLVAhvVem", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 19, "type": "Watch Video (45s)", "url": "https://youtu.be/Idek3A89slQ?si=onRru3zLmNC-Cvt", "commission": 400, "credit_points": 4, "is_prepaid": false },
      { "task_id": 20, "type": "Prepaid Task #4", "url": "https://youtu.be/LK11EmCjJzQ?si=Q3s0EJYu4GKC5XWq", "commission": 800, "credit_points": 9, "is_prepaid": true, "prepaid_value": 1000000 }
    ]
  },
  {
    "level": 10,
    "title": "Level 10",
    "total_tasks": 20,
    "level_reward": 15000,
    "total_credit_points": 100,
    "tasks": [
      { "task_id": 1, "type": "Subscribe", "url": "https://youtu.be/Z22mFwbCrCA?si=9Yjc9AH0eRZ4FNxb", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 2, "type": "Like and Comment", "url": "https://youtu.be/PGpb6Zc4KkE?si=hd0i40qWqeRPca4L", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 3, "type": "Watch Video (30s)", "url": "https://youtu.be/YHccUdhUE_Y?si=u-PDsW3JgEdo5llT", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 4, "type": "Watch Video (45s)", "url": "https://youtu.be/RVpKbiTvLWY?si=BpMN-6bpskK0ORfp", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 5, "type": "Prepaid Task #1", "url": "https://youtu.be/AJtkuFN1apc?si=ampDjQmn6PkH5PWs", "commission": 1000, "credit_points": 9, "is_prepaid": true, "prepaid_value": 1200000 },
      { "task_id": 6, "type": "Subscribe", "url": "https://youtu.be/k8eR5sBUCPw?si=tMuw34hpQu6CC5Fe", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 7, "type": "Like and Comment", "url": "https://youtu.be/LSKRceF5ykE?si=EJkkg6RzukZppH0y", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 8, "type": "Watch Video (30s)", "url": "https://youtu.be/KPIC2P_jFfU?si=6Lcs9aV9QdjMDAGO", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 9, "type": "Watch Video (45s)", "url": "https://youtu.be/qOWVl6j87nI?si=rMV76Ws1W3PnzqpC", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 10, "type": "Prepaid Task #2", "url": "https://youtu.be/UrjimhELcok?si=WRKmKc2Gcyje6pTV", "commission": 1000, "credit_points": 9, "is_prepaid": true, "prepaid_value": 1500000 },
      { "task_id": 11, "type": "Subscribe", "url": "https://youtu.be/pLF0bhcY5l8?si=4cRiZSz35yJ1f8q6", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 12, "type": "Like and Comment", "url": "https://youtu.be/JdPkgySQkyU?si=htapyrUIMYzOr_pE", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 13, "type": "Watch Video (30s)", "url": "https://youtu.be/OUdF9tyMlgM?si=rCXLot9IZombP88f", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 14, "type": "Watch Video (45s)", "url": "https://youtu.be/OQLWQEb-FgY?si=OOmTvdyEJb2U7VJV", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 15, "type": "Prepaid Task #3", "url": "https://youtu.be/p8ZHLMusfEk?si=G1GFQzDwT77oIEfc", "commission": 1000, "credit_points": 9, "is_prepaid": true, "prepaid_value": 1900000 },
      { "task_id": 16, "type": "Subscribe", "url": "https://youtu.be/mYDrGq0OHhQ?si=thc2AaWGV4GbAHAW", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 17, "type": "Like and Comment", "url": "https://youtu.be/-wrAWg_oSfE?si=iVDPEDYHDJV2G119", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 18, "type": "Watch Video (30s)", "url": "https://youtu.be/y8bFjc1gucQ?si=rwg40AmHWnb0iwIj", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 19, "type": "Watch Video (45s)", "url": "https://youtu.be/7lEqFKmCoaE?si=8HHU7uOV568gxPmn", "commission": 500, "credit_points": 4, "is_prepaid": false },
      { "task_id": 20, "type": "Prepaid Task #4", "url": "https://youtu.be/2toTTlle6Vs?si=lykA3vdnPTgRclZi", "commission": 1000, "credit_points": 9, "is_prepaid": true, "prepaid_value": 2500000 }
    ]
  }
];
